import Foundation

struct HermesConfigurationPayload: Codable, Sendable {
    let provider: String
    let model: String
    let environment: [String: String]
    let profileID: String
    let displayName: String
}

private struct HermesModelCatalogPayload: Codable, Sendable {
    let provider: String
    let environment: [String: String]
}

enum HermesConfigurationService {
    private static var defaultHermesHome: URL {
        AppPaths.root.appendingPathComponent("home/.hermes", isDirectory: true)
    }

    private static func profileHome(for profileID: String) -> URL {
        if profileID == HermesProfileID.defaultProfile { return defaultHermesHome }
        return defaultHermesHome.appendingPathComponent("profiles/\(profileID)", isDirectory: true)
    }

    private static func isolatedEnvironment(profileID: String = HermesProfileID.defaultProfile) -> [String: String] {
        let home = AppPaths.root.appendingPathComponent("home", isDirectory: true)
        return [
            "HOME": home.path,
            "HERMES_HOME": profileHome(for: profileID).path,
        ]
    }

    static func loadProviders() async throws -> [HermesProviderDescriptor] {
        let python = AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent/venv/bin/python")
        let helper = AppPaths.root.appendingPathComponent("helpers/list_hermes_providers.py")
        let result = try await CommandRunner.run(
            executable: python,
            arguments: [helper.path],
            currentDirectory: AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent"),
            environment: isolatedEnvironment()
        )
        guard result.succeeded else { throw StoreError.commandFailed(result.output) }
        return try JSONDecoder().decode([HermesProviderDescriptor].self, from: Data(result.output.utf8))
    }

    static func loadProfiles() async throws -> [HermesProfile] {
        let python = defaultHermesHome.appendingPathComponent("hermes-agent/venv/bin/python")
        let helper = AppPaths.root.appendingPathComponent("helpers/list_hermes_profiles.py")
        let result = try await CommandRunner.run(
            executable: python,
            arguments: [helper.path],
            currentDirectory: defaultHermesHome.appendingPathComponent("hermes-agent"),
            environment: isolatedEnvironment()
        )
        guard result.succeeded else { throw StoreError.commandFailed(result.output) }
        return try JSONDecoder().decode([HermesProfile].self, from: Data(result.output.utf8))
    }

    static func loadModels(
        provider: HermesProviderDescriptor,
        environment: [String: String]
    ) async throws -> [String] {
        var payloadEnvironment = environment
        if payloadEnvironment["baseURL", default: ""].isEmpty {
            let overrideField = provider.fields.first { !$0.secret && $0.name.localizedCaseInsensitiveContains("BASE_URL") }
            payloadEnvironment["baseURL"] = overrideField.flatMap { environment[$0.name] } ?? provider.defaultBaseURL
        }
        let payload = HermesModelCatalogPayload(provider: provider.slug, environment: payloadEnvironment)
        let input = try JSONEncoder().encode(payload)
        let python = AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent/venv/bin/python")
        let helper = AppPaths.root.appendingPathComponent("helpers/list_hermes_models.py")
        let result = try await CommandRunner.run(
            executable: python,
            arguments: [helper.path],
            currentDirectory: AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent"),
            standardInput: input,
            environment: isolatedEnvironment()
        )
        guard result.succeeded else { throw StoreError.commandFailed(result.output) }
        return try JSONDecoder().decode([String].self, from: Data(result.output.utf8))
    }

    static func defaultEnvironmentValue(named name: String) -> String? {
        guard name.range(of: "^[A-Za-z_][A-Za-z0-9_]*$", options: .regularExpression) != nil,
              let contents = try? String(contentsOf: defaultHermesHome.appendingPathComponent(".env"), encoding: .utf8) else {
            return nil
        }
        let prefix = "\(name)="
        guard var value = contents.split(whereSeparator: \.isNewline)
            .map(String.init)
            .first(where: { $0.hasPrefix(prefix) })
            .map({ String($0.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces) }) else {
            return nil
        }
        if value.count >= 2,
           (value.hasPrefix("\"") && value.hasSuffix("\"") || value.hasPrefix("'") && value.hasSuffix("'")) {
            value.removeFirst()
            value.removeLast()
        }
        return value.isEmpty ? nil : value
    }

    static func configure(
        provider: HermesProviderDescriptor,
        model: String,
        environment: [String: String],
        profileID: String,
        displayName: String
    ) async throws -> CommandResult {
        let profileHome = profileHome(for: profileID)
        try FileManager.default.createDirectory(at: profileHome, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let payload = HermesConfigurationPayload(
            provider: provider.slug,
            model: model,
            environment: environment,
            profileID: profileID,
            displayName: displayName
        )
        let input = try JSONEncoder().encode(payload)
        let python = AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent/venv/bin/python")
        let helper = AppPaths.root.appendingPathComponent("helpers/configure_hermes.py")
        return try await CommandRunner.run(
            executable: python,
            arguments: [helper.path],
            currentDirectory: AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent"),
            standardInput: input,
            environment: isolatedEnvironment(profileID: profileID)
        )
    }

    static func authenticate(provider: HermesProviderDescriptor, profileID: String) async throws -> CommandResult {
        try FileManager.default.createDirectory(
            at: profileHome(for: profileID),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let hermes = AppPaths.root.appendingPathComponent("bin/hermes")
        return try await CommandRunner.run(
            executable: hermes,
            arguments: ["auth", "add", provider.slug, "--type", "oauth"],
            currentDirectory: AppPaths.root,
            standardInput: Data("\n".utf8),
            environment: isolatedEnvironment(profileID: profileID)
        )
    }
}
