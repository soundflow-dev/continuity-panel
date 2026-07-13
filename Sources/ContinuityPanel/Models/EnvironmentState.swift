import Foundation

struct EnvironmentState: Sendable {
    var engineInstalled = false
    var missionControlRunning = false
    var installedAgents: Set<AgentKind> = []
    var commandLineToolsAvailable = false

    func isInstalled(_ agent: AgentKind) -> Bool {
        installedAgents.contains(agent)
    }
}

struct ProjectInfo: Identifiable, Hashable, Sendable {
    let name: String
    let url: URL

    var id: URL { url }
}

struct ActivityEntry: Identifiable, Sendable {
    enum Level: Sendable {
        case info
        case success
        case error
    }

    let id = UUID()
    let date: Date
    let message: String
    let level: Level
}
