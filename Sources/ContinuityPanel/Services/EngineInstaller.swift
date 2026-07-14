import Foundation

enum EngineInstallerError: LocalizedError {
    case bundledEngineMissing

    var errorDescription: String? {
        "The app bundle does not contain the ContinuityPanel engine."
    }
}

enum EngineInstaller {
    private static let executableNames = [
        "install.sh", "Install ContinuityPanel.command", "add-agent", "codex", "hermes",
        "check-hermes-profile-idle", "delete-project", "enqueue-project-analysis", "ensure-hermes-agent", "import-project", "install-service",
        "list-project-agents", "mc", "new-project", "remove-hermes-profile", "run-mission-control", "start", "status",
        "stop", "sync-projects"
    ]

    static func synchronizeBundledEngine() throws {
        guard let resourceURL = Bundle.main.resourceURL else {
            throw EngineInstallerError.bundledEngineMissing
        }
        let source = resourceURL.appendingPathComponent("Engine", isDirectory: true)
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw EngineInstallerError.bundledEngineMissing
        }

        try FileManager.default.createDirectory(at: AppPaths.root, withIntermediateDirectories: true)
        for item in try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) {
            try merge(item, into: AppPaths.root.appendingPathComponent(item.lastPathComponent))
        }
        try applyExecutablePermissions()
    }

    private static func merge(_ source: URL, into destination: URL) throws {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: source.path, isDirectory: &isDirectory)
        if isDirectory.boolValue {
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            for child in try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) {
                try merge(child, into: destination.appendingPathComponent(child.lastPathComponent))
            }
        } else {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
        }
    }

    private static func applyExecutablePermissions() throws {
        let candidates = [AppPaths.root.appendingPathComponent("install.sh"), AppPaths.root.appendingPathComponent("Install ContinuityPanel.command")]
            + executableNames.map { AppPaths.root.appendingPathComponent("bin/\($0)") }
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        }
    }
}
