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
        .alert(alertTitle, isPresented: alertBinding) {
            if store.lastError != nil {
                Button("OK") { store.lastError = nil }
            } else {
                Button("Later", role: .cancel) { store.dismissHermesUpdateNotice() }
                Button("Open Agents & Models") {
                    store.dismissHermesUpdateNotice()
                    selection = .agents
                }
            }
        } message: {
            Text(store.lastError ?? store.hermesUpdateNotice ?? "Unknown error")
        }
    }

    private var alertTitle: String {
        store.lastError != nil ? "ContinuityPanel" : "Hermes Update Available"
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { store.lastError != nil || store.hermesUpdateNotice != nil },
            set: { presented in
                guard !presented else { return }
                if store.lastError != nil {
                    store.lastError = nil
                } else {
                    store.dismissHermesUpdateNotice()
                }
            }
        )
    }
}
