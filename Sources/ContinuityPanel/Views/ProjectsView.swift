import AppKit
import SwiftUI

struct ProjectsView: View {
    let store: EnvironmentStore
    @State private var showingNewProject = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projects stay local by default").font(.headline)
                    Text("Nothing is sent to GitHub until you choose an account, destination, and visibility.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Show in Finder") { store.revealProjects() }
                Button("New Local Project") { showingNewProject = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            if store.projects.isEmpty {
                ContentUnavailableView(
                    "No projects yet",
                    systemImage: "folder.badge.plus",
                    description: Text("Create a local project now. GitHub connection will always be a separate, explicit action.")
                )
            } else {
                List(store.projects) { project in
                    HStack {
                        Image(systemName: "folder.fill").foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                            Text(project.url.path).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Button("Open") { NSWorkspace.shared.open(project.url) }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectView(store: store)
        }
    }
}

private struct NewProjectView: View {
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New local project").font(.title2.bold())
            TextField("Project name", text: $name)
                .textFieldStyle(.roundedBorder)
            Label("A Git repository and durable AGENTS.md / PROJECT_STATE.md handoff files will be created locally.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    Task {
                        if await store.createProject(named: name) { dismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!ProjectName.isValid(ProjectName.normalized(name)) || store.isBusy)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
