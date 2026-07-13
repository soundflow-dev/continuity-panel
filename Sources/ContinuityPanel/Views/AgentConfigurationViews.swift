import SwiftUI

struct HermesConfigurationView: View {
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var provider = HermesProvider.openRouter
    @State private var model = ""
    @State private var apiKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Configure Hermes").font(.title2.bold())
            Text("Hermes can switch models later without requiring another installation.")
                .foregroundStyle(.secondary)
            Form {
                Picker("Cloud provider", selection: $provider) {
                    ForEach(HermesProvider.allCases) { item in Text(item.title).tag(item) }
                }
                TextField("Model (\(provider.modelExample))", text: $model)
                SecureField("API key", text: $apiKey)
                Text("The key is written to Hermes' private environment file with restricted permissions. It is never committed to Git.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save Configuration") {
                    Task {
                        if await store.configureHermes(provider: provider, model: model, apiKey: apiKey) {
                            apiKey = ""
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isEmpty || apiKey.isEmpty || store.isBusy)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

struct ProviderConnectionView: View {
    let provider: CloudProvider
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(provider.title, systemImage: provider.systemImage)
                .font(.title2.bold())
            Text("Connect this provider once, then assign it to any compatible agent.")
                .foregroundStyle(.secondary)
            SecureField(provider.keyEnvironment, text: $apiKey)
                .textFieldStyle(.roundedBorder)
            Label("Stored in your macOS Keychain — never in the ContinuityPanel repository.", systemImage: "key.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Connect") {
                    if store.connectProvider(provider, apiKey: apiKey) {
                        apiKey = ""
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
