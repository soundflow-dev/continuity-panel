import SwiftUI

struct HermesProfileEditorView: View {
    let store: EnvironmentStore
    var editingProfile: HermesProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var providers: [HermesProviderDescriptor] = []
    @State private var selectedProviderID: String?
    @State private var searchText = ""
    @State private var model = ""
    @State private var values: [String: String] = [:]
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var profileName = ""
    @State private var createAgent = true
    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelLoadError: String?

    private var profileID: String {
        editingProfile?.id ?? HermesProfileID.suggested(from: profileName)
    }

    private var isEditing: Bool {
        editingProfile != nil
    }

    init(store: EnvironmentStore, editingProfile: HermesProfile? = nil) {
        self.store = store
        self.editingProfile = editingProfile
    }

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
            .navigationTitle(selectedProvider?.label ?? (isEditing ? "Edit Hermes profile" : "New Hermes profile"))
        }
        .frame(width: 900, height: 620)
        .task { await loadCatalog() }
        .onChange(of: selectedProviderID) { _, _ in
            guard !isLoading else { return }
            model = ""
            values = [:]
            modelLoadError = nil
            availableModels = selectedProvider?.models ?? []
            if let provider = selectedProvider {
                Task { await refreshModels(provider) }
            }
        }
    }

    private func providerForm(_ provider: HermesProviderDescriptor) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Hermes profile") {
                    VStack(alignment: .leading, spacing: 10) {
                        if isEditing {
                            LabeledContent("Profile name") {
                                Text(profileName).font(.body.weight(.medium))
                            }
                        } else {
                            TextField("Profile name, for example GLM 5.2", text: $profileName)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledContent("Profile ID") {
                            Text(profileID.isEmpty ? "Created from the profile name" : profileID)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        if isEditing, editingProfile?.isDefault != true {
                            Label("The Mission Control agent will be synchronized", systemImage: "link")
                                .font(.callout)
                        } else if !isEditing {
                            Toggle("Create a Mission Control agent for this profile", isOn: $createAgent)
                        }
                        Text(isEditing
                             ? "The profile name and ID stay fixed so existing Mission Control tasks keep their association. Provider, model, endpoint, and credentials can be changed."
                             : "The agent remains permanently associated with this provider and model.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

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
                                Task {
                                    if await store.authenticateHermes(provider: provider, profileID: profileID) {
                                        await refreshModels(provider)
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(store.isBusy || !isValidProfileID)
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
                        if !availableModels.isEmpty {
                            HStack {
                                Picker("Model name", selection: $model) {
                                    Text("Choose a model…").tag("")
                                    ForEach(availableModels, id: \.self) { modelID in
                                        Text(modelID).tag(modelID)
                                    }
                                }
                                .pickerStyle(.menu)
                                Button {
                                    Task { await refreshModels(provider) }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .help("Refresh models from \(provider.label)")
                                .disabled(isLoadingModels)
                            }
                            HStack(spacing: 6) {
                                if isLoadingModels { ProgressView().controlSize(.small) }
                                Text(isLoadingModels
                                     ? "Loading the live model catalog…"
                                     : "\(availableModels.count) models available from \(provider.label).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            DisclosureGroup("Enter a model ID manually") {
                                TextField("Exact model identifier", text: $model)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.top, 6)
                            }
                        } else {
                            TextField("Model name", text: $model)
                                .textFieldStyle(.roundedBorder)
                        }
                        if let modelLoadError {
                            Label(modelLoadError, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Text(!availableModels.isEmpty
                             ? "The list is loaded from the provider when credentials are available; the Hermes catalog is used as an offline fallback."
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
                                        SecureField(
                                            store.hasHermesCredential(provider: provider.slug, field: field.name)
                                                ? "Saved credential — leave blank to reuse"
                                                : "Enter \(field.name)",
                                            text: valueBinding(for: field.name)
                                        )
                                            .textFieldStyle(.roundedBorder)
                                    } else {
                                        TextField("Optional", text: valueBinding(for: field.name))
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            Text("Credentials are saved once in macOS Keychain and can be reused by other profiles for this provider.")
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
                    Button(isEditing ? "Save Changes" : "Create Profile & Agent") {
                        Task {
                            if await store.configureHermesProfile(
                                provider: provider,
                                model: model,
                                environment: values,
                                profileID: profileID,
                                displayName: profileName.trimmingCharacters(in: .whitespacesAndNewlines),
                                createAgent: createAgent
                            ) {
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
        isValidProfileID
            && !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && provider.fields.filter(\.required).allSatisfy {
                !(values[$0.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || ($0.secret && store.hasHermesCredential(provider: provider.slug, field: $0.name))
            }
    }

    private var isValidProfileID: Bool {
        profileID == HermesProfileID.defaultProfile || HermesProfileID.isValid(profileID)
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
            if let editingProfile {
                profileName = editingProfile.displayName
                model = editingProfile.model
                createAgent = !editingProfile.isDefault
                selectedProviderID = providers.first(where: { $0.id == editingProfile.provider })?.id
                    ?? providers.first?.id
                availableModels = selectedProvider?.models ?? []
            } else {
                selectedProviderID = providers.first?.id
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
        if let provider = selectedProvider {
            await refreshModels(provider)
        }
    }

    private func refreshModels(_ provider: HermesProviderDescriptor) async {
        isLoadingModels = true
        modelLoadError = nil
        do {
            let models = try await store.loadHermesModels(
                provider: provider,
                environment: values,
                profileID: HermesProfileID.isValid(profileID) ? profileID : HermesProfileID.defaultProfile
            )
            guard selectedProviderID == provider.id else { return }
            if !model.isEmpty && !models.contains(model) {
                availableModels = [model] + models
            } else {
                availableModels = models
            }
        } catch {
            guard selectedProviderID == provider.id else { return }
            availableModels = provider.models
            modelLoadError = "Could not refresh the live catalog. Showing the Hermes fallback list."
        }
        if selectedProviderID == provider.id {
            isLoadingModels = false
        }
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
