import SwiftUI

struct OverviewView: View {
    let store: EnvironmentStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your local agent workspace")
                            .font(.largeTitle.bold())
                        Text("Switch agents and cloud models without losing the project's durable context.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 48))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.cyan, .indigo)
                }

                if store.isBusy {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(store.busyMessage)
                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    StatusCard(
                        title: "Environment",
                        value: store.state.engineInstalled ? "Installed" : "Not installed",
                        detail: store.state.engineInstalled ? "Ready in Application Support" : "Installs Mission Control and isolated runtimes",
                        systemImage: "shippingbox",
                        color: store.state.engineInstalled ? .green : .orange
                    )
                    StatusCard(
                        title: "Mission Control",
                        value: store.state.missionControlRunning ? "Running" : "Stopped",
                        detail: "Local dashboard on 127.0.0.1:3000",
                        systemImage: "rectangle.3.group",
                        color: store.state.missionControlRunning ? .green : .secondary
                    )
                    StatusCard(
                        title: "Agents",
                        value: "\(store.state.installedAgents.count) installed",
                        detail: "\(AgentKind.allCases.count) available in the built-in catalog",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        color: .blue
                    )
                    StatusCard(
                        title: "Projects",
                        value: "\(store.projects.count) local",
                        detail: "GitHub publishing is always explicit",
                        systemImage: "folder",
                        color: .purple
                    )
                }

                GroupBox("Quick actions") {
                    HStack {
                        if !store.state.engineInstalled {
                            Button("Install Environment") {
                                Task { await store.installEnvironment() }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Repair / Update") {
                                Task { await store.installEnvironment() }
                            }
                            if store.state.missionControlRunning {
                                Button("Open Mission Control") { store.openMissionControl() }
                                    .buttonStyle(.borderedProminent)
                                Button("Stop") { Task { await store.stopMissionControl() } }
                            } else {
                                Button("Start Mission Control") { Task { await store.startMissionControl() } }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(value).font(.title3.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
