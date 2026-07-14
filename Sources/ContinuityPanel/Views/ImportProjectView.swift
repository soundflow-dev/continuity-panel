import SwiftUI

struct ImportProjectView: View {
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var source: URL?
    @State private var name = ""
    @State private var analyzeAfterImport = true
    @State private var selectedAgentID: Int?
    @State private var runTests = false

    private var selectedAgent: ProjectAgentInfo? {
        store.projectAgents.first { $0.id == selectedAgentID }
    }

    private var canImport: Bool {
        source != nil && ProjectName.isValid(ProjectName.normalized(name)) &&
            (!analyzeAfterImport || selectedAgent != nil) && !store.isBusy
    }

    private var folderIcon: String {
        source == nil ? "folder.badge.plus" : "folder.fill"
    }

    private var folderColor: Color {
        source == nil ? .secondary : .blue
    }

    private var folderPath: String {
        source?.path ?? "No folder selected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Import existing project").font(.title2.bold())
                Text("Continue a project created in Codex, Hermes, Xcode, VS Code, or any other tool.")
                    .foregroundStyle(.secondary)
            }

            GroupBox("Project folder") {
                HStack(spacing: 12) {
                    Image(systemName: folderIcon)
                        .foregroundStyle(folderColor)
                    Text(folderPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(source == nil ? Color.secondary : Color.primary)
                    Spacer()
                    Button(source == nil ? "Choose…" : "Change…") {
                        guard let chosen = ProjectFolderPicker.chooseFolder() else { return }
                        source = chosen
                        name = ProjectName.suggested(from: chosen.lastPathComponent)
                    }
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("ContinuityPanel project name").font(.headline)
                TextField("Project name", text: $name)
                    .textFieldStyle(.roundedBorder)
                Text("Letters, numbers, dashes, and underscores only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Analyze the project after import", isOn: $analyzeAfterImport)
                        .font(.headline)

                    if analyzeAfterImport {
                        if store.projectAgents.isEmpty {
                            Label("Create and configure an agent in Mission Control before requesting automatic analysis.", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Picker("Agent", selection: $selectedAgentID) {
                                Text("Choose an agent").tag(nil as Int?)
                                ForEach(store.projectAgents) { agent in
                                    Text("\(agent.name) — \(agent.runtimeLabel)").tag(agent.id as Int?)
                                }
                            }
                            Toggle("Run existing tests when safe", isOn: $runTests)
                            Text("The agent will inspect the repository and update PROJECT_STATE.md. It will not install dependencies or change application code.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
            }

            Label("The complete folder is copied, including hidden files and Git history. The original is never moved or modified.", systemImage: "checkmark.shield")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                if store.isBusy {
                    ProgressView().controlSize(.small)
                    Text(store.busyMessage).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Import Project") {
                    guard let source else { return }
                    Task {
                        let agent = analyzeAfterImport ? selectedAgent : nil
                        if await store.importProject(from: source, named: name, analyzeWith: agent, runTests: runTests) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canImport)
            }
        }
        .padding(24)
        .frame(width: 640)
        .task {
            await store.refreshProjectAgents()
            if selectedAgentID == nil {
                selectedAgentID = store.projectAgents.first?.id
            }
        }
        .onChange(of: store.projectAgents) { _, agents in
            if selectedAgentID == nil || !agents.contains(where: { $0.id == selectedAgentID }) {
                selectedAgentID = agents.first?.id
            }
        }
    }
}
