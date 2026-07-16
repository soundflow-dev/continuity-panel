import Foundation

enum HermesUpdateChannel: String, CaseIterable, Identifiable, Sendable {
    case stable
    case latest

    var id: Self { self }
    var title: String { self == .stable ? "Stable" : "Latest / Main" }
    var detail: String {
        switch self {
        case .stable: "Recommended. Uses the newest published Hermes release."
        case .latest: "Experimental. Uses the newest upstream code before a release is published."
        }
    }
}

struct HermesUpdateStatus: Codable, Equatable, Sendable {
    let installedVersion: String
    let installedCommit: String
    let stableTag: String
    let stableAvailable: Bool
    let latestCommit: String
    let latestCommitsBehind: Int
    let latestAvailable: Bool

    func hasUpdate(for channel: HermesUpdateChannel) -> Bool {
        channel == .stable ? stableAvailable : latestAvailable
    }

    var notificationMessage: String {
        if stableAvailable {
            return "Hermes \(stableTag) is available. Open Agents & Models to review and install it."
        }
        return "Hermes has \(latestCommitsBehind) newer upstream changes available on Latest / Main. Your stable installation remains supported."
    }
}
