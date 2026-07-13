import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case overview
    case agents
    case projects
    case activity

    var id: Self { self }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .agents: "Agents & Models"
        case .projects: "Projects"
        case .activity: "Activity"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "rectangle.grid.2x2"
        case .agents: "point.3.connected.trianglepath.dotted"
        case .projects: "folder"
        case .activity: "list.bullet.rectangle"
        }
    }
}
