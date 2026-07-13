import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppSection?
    let store: EnvironmentStore

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(AppSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }

            Section("System") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(store.state.missionControlRunning ? Color.green : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(store.state.missionControlRunning ? "Mission Control running" : "Mission Control stopped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Image(systemName: "infinity")
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ContinuityPanel").font(.caption).fontWeight(.semibold).lineLimit(1)
                    Text("Keep the context").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
        }
    }
}
