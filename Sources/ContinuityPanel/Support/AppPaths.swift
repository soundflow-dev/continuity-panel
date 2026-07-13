import Foundation

enum AppPaths {
    static let folderName = "ContinuityPanel"

    static var root: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(folderName, isDirectory: true)
    }

    static var projects: URL { root.appendingPathComponent("projects", isDirectory: true) }
    static var missionControl: URL { root.appendingPathComponent("mission-control", isDirectory: true) }
    static func binary(for agent: AgentKind) -> URL {
        root.appendingPathComponent(agent.binaryRelativePath)
    }
}
