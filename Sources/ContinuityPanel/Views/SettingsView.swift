import SwiftUI

struct SettingsView: View {
    let store: EnvironmentStore

    var body: some View {
        TabView {
            Form {
                LabeledContent("Environment", value: AppPaths.root.path)
                LabeledContent("Automatic startup", value: "Enabled after installation")
                LabeledContent("Mission Control", value: "http://127.0.0.1:3000")
                HStack {
                    Button("Reveal Environment") { store.revealEnvironment() }
                    Button("Refresh") { Task { await store.refresh() } }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("General", systemImage: "gearshape") }

            Form {
                Text("Cloud provider secrets are stored in the macOS Keychain. Agent-specific credentials remain in the isolated ContinuityPanel environment and are excluded from Git.")
                Text("The dashboard only listens on 127.0.0.1 by default.")
            }
            .formStyle(.grouped)
            .tabItem { Label("Security", systemImage: "lock.shield") }
        }
        .frame(width: 620, height: 320)
    }
}
