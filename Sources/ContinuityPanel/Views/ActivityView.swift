import SwiftUI

struct ActivityView: View {
    let store: EnvironmentStore

    var body: some View {
        if store.activity.isEmpty {
            ContentUnavailableView(
                "No activity yet",
                systemImage: "list.bullet.rectangle",
                description: Text("Installation, agent, provider, and project actions will appear here.")
            )
        } else {
            List(store.activity) { entry in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon(for: entry.level))
                        .foregroundStyle(color(for: entry.level))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.message)
                        Text(entry.date, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func icon(for level: ActivityEntry.Level) -> String {
        switch level {
        case .info: "info.circle"
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private func color(for level: ActivityEntry.Level) -> Color {
        switch level {
        case .info: .blue
        case .success: .green
        case .error: .red
        }
    }
}
