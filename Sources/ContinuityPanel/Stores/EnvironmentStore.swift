import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class EnvironmentStore {
    private(set) var state = EnvironmentState()
    private(set) var projects: [ProjectInfo] = []
    private(set) var projectAgents: [ProjectAgentInfo] = []
    private(set) var hermesProfiles: [HermesProfile] = []
    private(set) var activity: [ActivityEntry] = []
    private(set) var connectedProviders: Set<CloudProvider> = []
    private(set) var isBusy = false
    private(set) var busyMessage = ""
    var lastError: String?

    func refresh() async {
        let fileManager = FileManager.default
        state.engineInstalled = fileManager.fileExists(atPath: AppPaths.missionControl.appendingPathComponent("package.json").path)
        state.installedAgents = Set(AgentKind.allCases.filter { fileManager.isExecutableFile(atPath: AppPaths.binary(for: $0).path) })
        state.commandLineToolsAvailable = await commandLineToolsAvailable()
        if state.engineInstalled {
            state.missionControlRunning = await missionControlIsRunning()
        } else {
            state.missionControlRunning = false
        }
        connectedProviders = Set(CloudProvider.allCases.filter { KeychainService.contains(account: $0.rawValue) })
        projects = loadProjects()
        await refreshProjectAgents()
        await refreshHermesProfiles()
    }

    func installEnvironment() async {
        await perform("Installing the ContinuityPanel environment…", success: "Environment installed") {
            try EngineInstaller.synchronizeBundledEngine()
            return try await self.runScript("install.sh")
        }
    }

    func startMissionControl() async {
        await perform("Starting Mission Control…", success: "Mission Control started") {
            try await self.runScript("bin/start")
        }
    }

    func stopMissionControl() async {
        await perform("Stopping Mission Control…", success: "Mission Control stopped") {
            try await self.runScript("bin/stop")
        }
    }

    func installAgent(_ agent: AgentKind) async {
        await perform("Adding \(agent.title)…", success: "\(agent.title) added") {
            try EngineInstaller.synchronizeBundledEngine()
            guard self.state.engineInstalled else {
                throw StoreError.environmentRequired
            }
            return try await self.runScript("bin/add-agent", arguments: [agent.rawValue])
        }
    }

    func signInToCodex() async {
        await perform("Waiting for Codex browser sign-in…", success: "Codex sign-in completed") {
            try await self.runScript("bin/codex", arguments: ["login"])
        }
    }

    func configureHermesProfile(
        provider: HermesProviderDescriptor,
        model: String,
        environment: [String: String],
        profileID: String,
        displayName: String,
        createAgent: Bool
    ) async -> Bool {
        guard profileID == HermesProfileID.defaultProfile || HermesProfileID.isValid(profileID) else {
            lastError = "Use a profile name containing letters, numbers, dashes, or underscores."
            return false
        }

        var resolvedEnvironment = environment
        do {
            for field in provider.fields where field.secret {
                let account = hermesCredentialAccount(provider: provider.slug, field: field.name)
                let supplied = (environment[field.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !supplied.isEmpty {
                    try KeychainService.save(supplied, account: account)
                    resolvedEnvironment[field.name] = supplied
                } else if let saved = try KeychainService.load(account: account), !saved.isEmpty {
                    resolvedEnvironment[field.name] = saved
                } else if let existing = HermesConfigurationService.defaultEnvironmentValue(named: field.name), !existing.isEmpty {
                    try KeychainService.save(existing, account: account)
                    resolvedEnvironment[field.name] = existing
                }
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }

        let missingRequired = provider.fields.filter(\.required).contains {
            (resolvedEnvironment[$0.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !missingRequired else {
            lastError = "Enter the required provider credentials before saving this profile."
            return false
        }

        var configured = false
        await perform("Configuring Hermes profile…", success: "Hermes profile \(displayName) configured") {
            let result = try await HermesConfigurationService.configure(
                provider: provider,
                model: model,
                environment: resolvedEnvironment,
                profileID: profileID,
                displayName: displayName
            )
            guard result.succeeded else { return result }

            if createAgent && profileID != HermesProfileID.defaultProfile {
                let agentResult = try await self.runScript(
                    "bin/ensure-hermes-agent",
                    arguments: [profileID, displayName, provider.slug, model]
                )
                configured = agentResult.succeeded
                return CommandResult(
                    status: agentResult.status,
                    output: [result.output, agentResult.output].filter { !$0.isEmpty }.joined(separator: "\n")
                )
            }

            configured = true
            return result
        }
        return configured
    }

    func authenticateHermes(provider: HermesProviderDescriptor, profileID: String) async -> Bool {
        var authenticated = false
        await perform("Signing in to \(provider.label)…", success: "Hermes connected to \(provider.label)") {
            let result = try await HermesConfigurationService.authenticate(provider: provider, profileID: profileID)
            authenticated = result.succeeded
            return result
        }
        return authenticated
    }

    func hasHermesCredential(provider: String, field: String) -> Bool {
        KeychainService.contains(account: hermesCredentialAccount(provider: provider, field: field))
            || HermesConfigurationService.defaultEnvironmentValue(named: field) != nil
    }

    func refreshHermesProfiles() async {
        guard state.isInstalled(.hermes) else {
            hermesProfiles = []
            return
        }
        do {
            try EngineInstaller.synchronizeBundledEngine()
            hermesProfiles = try await HermesConfigurationService.loadProfiles()
        } catch {
            hermesProfiles = []
        }
    }

    func removeHermesProfile(_ profile: HermesProfile) async -> Bool {
        guard !profile.isDefault, HermesProfileID.isValid(profile.id) else {
            lastError = "The shared default Hermes configuration cannot be removed here."
            return false
        }
        var removed = false
        await perform("Moving Hermes profile \(profile.displayName) to Trash…", success: "Hermes profile \(profile.displayName) moved to Trash") {
            try EngineInstaller.synchronizeBundledEngine()
            let result = try await self.runScript("bin/remove-hermes-profile", arguments: [profile.id])
            removed = result.succeeded
            return result
        }
        return removed
    }

    private func hermesCredentialAccount(provider: String, field: String) -> String {
        "hermes.\(provider).\(field)"
    }

    func connectProvider(_ provider: CloudProvider, apiKey: String) -> Bool {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastError = "Enter an API key before connecting the provider."
            return false
        }
        do {
            try KeychainService.save(apiKey, account: provider.rawValue)
            connectedProviders.insert(provider)
            activity.insert(ActivityEntry(date: .now, message: "\(provider.title) connected", level: .success), at: 0)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func disconnectProvider(_ provider: CloudProvider) {
        do {
            try KeychainService.remove(account: provider.rawValue)
            connectedProviders.remove(provider)
            activity.insert(ActivityEntry(date: .now, message: "\(provider.title) disconnected", level: .info), at: 0)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func createProject(named rawName: String) async -> Bool {
        let name = ProjectName.normalized(rawName)
        guard ProjectName.isValid(name) else {
            lastError = "Use a short project name containing letters, numbers, dashes, or underscores."
            return false
        }
        var created = false
        await perform("Creating \(name)…", success: "Project \(name) created locally") {
            try EngineInstaller.synchronizeBundledEngine()
            let result = try await self.runScript("bin/new-project", arguments: [name])
            created = result.succeeded
            return result
        }
        return created
    }

    func deleteProject(_ project: ProjectInfo) async -> Bool {
        let projectsRoot = AppPaths.projects.standardizedFileURL
        let projectURL = project.url.standardizedFileURL
        guard projectURL.deletingLastPathComponent() == projectsRoot,
              ProjectName.isValid(project.name) else {
            lastError = "The selected project is outside the ContinuityPanel projects folder."
            return false
        }

        var deleted = false
        await perform("Moving \(project.name) to Trash…", success: "Project \(project.name) moved to Trash") {
            try EngineInstaller.synchronizeBundledEngine()
            let result = try await self.runScript("bin/delete-project", arguments: [project.name])
            deleted = result.succeeded
            return result
        }
        return deleted
    }

    func refreshProjectAgents() async {
        do {
            try EngineInstaller.synchronizeBundledEngine()
            let result = try await runScript("bin/list-project-agents")
            guard result.succeeded,
                  let data = result.output.data(using: .utf8) else {
                projectAgents = []
                return
            }
            projectAgents = try JSONDecoder().decode([ProjectAgentInfo].self, from: data)
        } catch {
            projectAgents = []
        }
    }

    func importProject(
        from source: URL,
        named rawName: String,
        analyzeWith agent: ProjectAgentInfo?,
        runTests: Bool
    ) async -> Bool {
        let name = ProjectName.normalized(rawName)
        guard ProjectName.isValid(name) else {
            lastError = "Use a short project name containing letters, numbers, dashes, or underscores."
            return false
        }
        guard source.standardizedFileURL != AppPaths.projects.appendingPathComponent(name).standardizedFileURL else {
            lastError = "This project is already inside ContinuityPanel."
            return false
        }

        var imported = false
        await perform("Importing \(name)…", success: "Project \(name) imported") {
            try EngineInstaller.synchronizeBundledEngine()
            let importResult = try await self.runScript("bin/import-project", arguments: [source.path, name])
            imported = importResult.succeeded
            return importResult
        }

        if imported, let agent {
            await perform("Scheduling analysis with \(agent.name)…", success: "Analysis scheduled with \(agent.name)") {
                try await self.runScript(
                    "bin/enqueue-project-analysis",
                    arguments: [name, String(agent.id), runTests ? "true" : "false"]
                )
            }
        }
        return imported
    }

    func revealProjects() {
        try? FileManager.default.createDirectory(at: AppPaths.projects, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([AppPaths.projects])
    }

    func revealEnvironment() {
        try? FileManager.default.createDirectory(at: AppPaths.root, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([AppPaths.root])
    }

    private func perform(
        _ message: String,
        success successMessage: String,
        operation: () async throws -> CommandResult
    ) async {
        guard !isBusy else { return }
        isBusy = true
        busyMessage = message
        lastError = nil
        activity.insert(ActivityEntry(date: .now, message: message, level: .info), at: 0)
        defer { isBusy = false; busyMessage = "" }

        do {
            let result = try await operation()
            guard result.succeeded else {
                throw StoreError.commandFailed(result.output)
            }
            activity.insert(ActivityEntry(date: .now, message: successMessage, level: .success), at: 0)
        } catch {
            lastError = error.localizedDescription
            activity.insert(ActivityEntry(date: .now, message: error.localizedDescription, level: .error), at: 0)
        }
        await refresh()
    }

    private func runScript(_ relativePath: String, arguments: [String] = []) async throws -> CommandResult {
        let script = AppPaths.root.appendingPathComponent(relativePath)
        return try await CommandRunner.run(executable: script, arguments: arguments, currentDirectory: AppPaths.root)
    }

    private func missionControlIsRunning() async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:3000/api/setup") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func commandLineToolsAvailable() async -> Bool {
        do {
            let result = try await CommandRunner.run(executable: URL(fileURLWithPath: "/usr/bin/xcrun"), arguments: ["--find", "git"])
            return result.succeeded
        } catch {
            return false
        }
    }

    private func loadProjects() -> [ProjectInfo] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: AppPaths.projects,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls.compactMap { url in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
            return ProjectInfo(name: url.lastPathComponent, url: url)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

enum StoreError: LocalizedError {
    case environmentRequired
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .environmentRequired:
            "Install the ContinuityPanel environment before adding an agent."
        case .commandFailed(let output):
            output.isEmpty ? "The command failed without returning details." : output
        }
    }
}

enum ProjectName {
    static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValid(_ value: String) -> Bool {
        guard !value.isEmpty, value.count <= 80, value.first != "." else { return false }
        return value.range(of: "^[A-Za-z0-9][A-Za-z0-9_-]*$", options: .regularExpression) != nil
    }

    static func suggested(from value: String) -> String {
        let folded = value.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
        let replaced = folded.replacingOccurrences(of: "[^A-Za-z0-9_-]+", with: "_", options: .regularExpression)
        return String(replaced.trimmingCharacters(in: CharacterSet(charactersIn: "_-")).prefix(80))
    }
}
