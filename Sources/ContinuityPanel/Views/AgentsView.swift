import SwiftUI

struct AgentsView: View {
    let store: EnvironmentStore
    @State private var selectedTab = AgentCatalogTab.agents
    @State private var hermesSheet = false
    @State private var providerToConnect: CloudProvider?

    var body: some View {
        VStack(spacing: 0) {
            Picker("Catalog", selection: $selectedTab) {
                ForEach(AgentCatalogTab.allCases) { tab in Text(tab.title).tag(tab) }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 14)], spacing: 14) {
                    if selectedTab == .agents {
                        ForEach(AgentKind.allCases) { agent in
                            AgentCard(agent: agent, store: store) {
                                if agent == .hermes { hermesSheet = true }
                            }
                        }
                    } else {
                        ForEach(CloudProvider.allCases) { provider in
                            ProviderCard(provider: provider, store: store) {
                                providerToConnect = provider
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
        }
        .sheet(isPresented: $hermesSheet) {
            HermesConfigurationView(store: store)
        }
        .sheet(item: $providerToConnect) { provider in
            ProviderConnectionView(provider: provider, store: store)
        }
    }
}

private enum AgentCatalogTab: String, CaseIterable, Identifiable {
    case agents
    case providers
    var id: Self { self }
    var title: String { self == .agents ? "Agents" : "Cloud Providers" }
}

private struct AgentCard: View {
    let agent: AgentKind
    let store: EnvironmentStore
    let configureHermes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: agent.systemImage)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(agent.title).font(.headline)
                    Text(agent.summary).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if store.state.isInstalled(agent) {
                    Label("Installed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            HStack {
                if store.state.isInstalled(agent) {
                    if agent == .codex {
                        Button("Sign in") { Task { await store.signInToCodex() } }
                    } else if agent == .hermes {
                        Button("Choose provider & model", action: configureHermes)
                    } else {
                        Text("Configuration adapter ready for the provider catalog.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Add Agent") { Task { await store.installAgent(agent) } }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.state.engineInstalled || store.isBusy)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ProviderCard: View {
    let provider: CloudProvider
    let store: EnvironmentStore
    let connect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: provider.systemImage)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.title).font(.headline)
                Text(provider.keyEnvironment).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            if store.connectedProviders.contains(provider) {
                Label("Connected", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Button("Disconnect") { store.disconnectProvider(provider) }
            } else {
                Button("Connect", action: connect).buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
