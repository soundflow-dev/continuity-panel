import SwiftUI

struct HermesProfilesView: View {
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewProfile = false
    @State private var profileBeingEdited: HermesProfile?
    @State private var profilePendingRemoval: HermesProfile?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hermes profiles").font(.title2.bold())
                    Text("Use different cloud models simultaneously through one Hermes installation.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Profile…") { showingNewProfile = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            if store.hermesProfiles.isEmpty {
                ContentUnavailableView(
                    "No Hermes profiles yet",
                    systemImage: "person.crop.rectangle.stack",
                    description: Text("Add a profile for each provider and model combination you want to use.")
                )
            } else {
                List(store.hermesProfiles) { profile in
                    HStack(spacing: 12) {
                        Image(systemName: profile.isDefault ? "gearshape" : "person.crop.rectangle")
                            .foregroundStyle(profile.isDefault ? Color.secondary : Color.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(profile.displayName).font(.headline)
                                if profile.isDefault {
                                    Text("Shared legacy profile")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.quaternary, in: Capsule())
                                }
                            }
                            Text("\(profile.provider.isEmpty ? "Unknown provider" : profile.provider) · \(profile.model.isEmpty ? "No model selected" : profile.model)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Edit…") {
                            profileBeingEdited = profile
                        }
                        Button("Remove…", role: .destructive) {
                            profilePendingRemoval = profile
                        }
                    }
                    .padding(.vertical, 5)
                }
            }

            Divider()
            HStack {
                Label("Profiles have separate configuration, sessions, and memory. Provider credentials can be shared securely.", systemImage: "key.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
        }
        .frame(width: 720, height: 520)
        .task { await store.refreshHermesProfiles() }
        .sheet(isPresented: $showingNewProfile, onDismiss: {
            Task { await store.refreshHermesProfiles() }
        }) {
            HermesProfileEditorView(store: store)
        }
        .sheet(item: $profileBeingEdited, onDismiss: {
            Task { await store.refreshHermesProfiles() }
        }) { profile in
            HermesProfileEditorView(store: store, editingProfile: profile)
        }
        .alert(
            "Remove Hermes profile?",
            isPresented: Binding(
                get: { profilePendingRemoval != nil },
                set: { if !$0 { profilePendingRemoval = nil } }
            ),
            presenting: profilePendingRemoval
        ) { profile in
            Button("Move Profile to Trash", role: .destructive) {
                profilePendingRemoval = nil
                Task { _ = await store.removeHermesProfile(profile) }
            }
            Button("Cancel", role: .cancel) {
                profilePendingRemoval = nil
            }
        } message: { profile in
            if profile.isDefault {
                Text("The default configuration, sessions, state, and memory will be moved to the macOS Trash. Hermes will remain installed, its Mission Control agent will be hidden, and shared provider credentials will remain in the macOS Keychain.")
            } else {
                Text("\(profile.displayName) will be moved to the macOS Trash and its Mission Control agent will be hidden. Shared provider credentials will remain available to other profiles.")
            }
        }
    }
}
