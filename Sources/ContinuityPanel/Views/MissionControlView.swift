import SwiftUI

struct MissionControlView: View {
    let store: EnvironmentStore
    @State private var browserState: EmbeddedBrowserState = .loading
    @State private var reloadToken = UUID()

    private let dashboardURL = URL(string: "http://127.0.0.1:3000")!

    var body: some View {
        Group {
            if !store.state.engineInstalled {
                unavailableView(
                    icon: "shippingbox",
                    title: "Install your agent workspace",
                    detail: "ContinuityPanel will install Mission Control locally and configure it to start automatically when you sign in to your Mac.",
                    buttonTitle: "Install Environment"
                ) {
                    Task { await store.installEnvironment() }
                }
            } else if !store.state.missionControlRunning {
                unavailableView(
                    icon: "power",
                    title: "Mission Control is stopped",
                    detail: "Start the local service to open your dashboard inside ContinuityPanel.",
                    buttonTitle: "Start Mission Control"
                ) {
                    Task { await store.startMissionControl() }
                }
            } else {
                ZStack {
                    EmbeddedMissionControlView(
                        url: dashboardURL,
                        reloadToken: reloadToken,
                        onStateChange: { browserState = $0 }
                    )

                    if browserState == .loading {
                        ProgressView("Opening Mission Control…")
                            .padding(18)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if case .failed(let message) = browserState {
                        unavailableView(
                            icon: "exclamationmark.arrow.triangle.2.circlepath",
                            title: "Mission Control did not respond",
                            detail: message,
                            buttonTitle: "Try Again"
                        ) {
                            reloadToken = UUID()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button {
                            reloadToken = UUID()
                        } label: {
                            Label("Reload Mission Control", systemImage: "arrow.clockwise")
                        }
                        .help("Reload the embedded Mission Control dashboard")
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if store.isBusy {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(store.busyMessage)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .padding(.top, 14)
            }
        }
    }

    private func unavailableView(
        icon: String,
        title: String,
        detail: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(detail)
                .frame(maxWidth: 480)
        } actions: {
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .disabled(store.isBusy)
        }
    }
}
