import SwiftUI

struct HermesConfigurationView: View {
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var providers: [HermesProviderDescriptor] = []
    @State private var selectedProviderID: String?
    @State private var searchText = ""
    @State private var model = ""
    @State private var values: [String: String] = [:]
    @State private var isLoading = true
    @State private var loadError: String?

    private var filteredProviders: [HermesProviderDescriptor] {
        guard !searchText.isEmpty else { return providers }
        return providers.filter {
            $0.label.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
                || $0.slug.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedProvider: HermesProviderDescriptor? {
        providers.first { $0.id == selectedProviderID }
    }

    var body: some View {
        NavigationSplitView {
            List(filteredProviders, selection: $selectedProviderID) { provider in
                VStack(alignment: .leading, spacing: 3) {
                    Text(provider.label).lineLimit(1)
                    Text(provider.authenticationLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .tag(provider.id)
            }
            .searchable(text: $searchText, prompt: "Search providers")
            .navigationTitle("Hermes providers")
            .navigationSplitViewColumnWidth(min: 230, ideal: 270, max: 330)
        } detail: {
            Group {
                if isLoading {
                    ProgressView("Reading the Hermes catalog…")
                } else if let loadError {
                    ContentUnavailableView(
                        "Could not load providers",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if let provider = selectedProvider {
                    providerForm(provider)
                } else {
                    ContentUnavailableView(
                        "Choose a provider",
                        systemImage: "network",
                        description: Text("Every provider shown here comes directly from the installed Hermes version.")
                    )
                }
            }
            .navigationTitle(selectedProvider?.label ?? "Configure Hermes")
        }
        .frame(width: 900, height: 620)
        .task { await loadCatalog() }
        .onChange(of: selectedProviderID) { _, _ in
            model = ""
            values = [:]
        }
    }

    private func providerForm(_ provider: HermesProviderDescriptor) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(provider.label).font(.title.bold())
                    Text(provider.description).foregroundStyle(.secondary)
                    Label(provider.authenticationLabel, systemImage: provider.usesAccountLogin ? "person.crop.circle.badge.checkmark" : "key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if provider.supportsBrowserLogin {
                    GroupBox("Account") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hermes will use its official authentication flow. A browser window may open.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Sign in to \(provider.label)") {
                                Task { _ = await store.authenticateHermes(provider: provider) }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(store.isBusy)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                } else if provider.authType == "external_process" {
                    GroupBox("External runtime") {
                        Text("This provider uses an installed companion process. Configure the provider and model below; Hermes starts the companion when needed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                }

                GroupBox("Provider and model") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Hermes provider ID") {
                            Text(provider.slug).font(.body.monospaced()).foregroundStyle(.secondary)
                        }
                        if !provider.defaultBaseURL.isEmpty {
                            LabeledContent("Default Base URL") {
                                Text(provider.defaultBaseURL)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                        }
                        if provider.hasModelCatalog {
                            Picker("Model name", selection: $model) {
                                Text("Choose a model…").tag("")
                                ForEach(provider.models, id: \.self) { modelID in
                                    Text(modelID).tag(modelID)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            TextField("Model name", text: $model)
                                .textFieldStyle(.roundedBorder)
                        }
                        Text(provider.hasModelCatalog
                             ? "Choose one of the models supported by this Hermes provider."
                             : "Enter the exact model identifier offered by the provider.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                if !provider.fields.isEmpty {
                    GroupBox("Connection") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(provider.fields) { field in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(field.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if field.secret {
                                        SecureField("Enter \(field.name)", text: valueBinding(for: field.name))
                                            .textFieldStyle(.roundedBorder)
                                    } else {
                                        TextField("Optional", text: valueBinding(for: field.name))
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            Text("Secrets are written only to Hermes' private environment with restricted permissions.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }

                HStack {
                    if let url = URL(string: provider.signupURL), !provider.signupURL.isEmpty {
                        Link("Provider website", destination: url)
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save Provider & Model") {
                        Task {
                            if await store.configureHermes(provider: provider, model: model, environment: values) {
                                values = [:]
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave(provider) || store.isBusy)
                }
            }
            .padding(24)
        }
    }

    private func canSave(_ provider: HermesProviderDescriptor) -> Bool {
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && provider.fields.filter(\.required).allSatisfy {
                !(values[$0.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    private func valueBinding(for name: String) -> Binding<String> {
        Binding(
            get: { values[name] ?? "" },
            set: { values[name] = $0 }
        )
    }

    private func loadCatalog() async {
        do {
            try EngineInstaller.synchronizeBundledEngine()
            providers = try await HermesConfigurationService.loadProviders()
            selectedProviderID = providers.first?.id
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
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
