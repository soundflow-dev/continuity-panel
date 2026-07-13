import SwiftUI

struct ContentView: View {
    let store: EnvironmentStore
    @State private var selection: AppSection? = .missionControl

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, store: store)
        } detail: {
            Group {
                switch selection ?? .missionControl {
                case .missionControl: MissionControlView(store: store)
                case .overview: OverviewView(store: store)
                case .agents: AgentsView(store: store)
                case .projects: ProjectsView(store: store)
                case .activity: ActivityView(store: store)
                }
            }
            .navigationTitle((selection ?? .missionControl).title)
            .toolbar {
                if selection != .missionControl {
                    ToolbarItem {
                        Button {
                            Task { await store.refresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(store.isBusy)
                    }
                }
            }
        }
        .alert("ContinuityPanel", isPresented: errorBinding) {
            Button("OK") { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "Unknown error")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { store.lastError != nil }, set: { if !$0 { store.lastError = nil } })
    }
}
