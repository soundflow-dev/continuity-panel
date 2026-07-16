import SwiftUI

struct HermesUpdateView: View {
    let store: EnvironmentStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hermesUpdateChannel") private var selectedChannelRaw = HermesUpdateChannel.stable.rawValue
    @State private var showingConfirmation = false

    private var selectedChannel: HermesUpdateChannel {
        get { HermesUpdateChannel(rawValue: selectedChannelRaw) ?? .stable }
        nonmutating set { selectedChannelRaw = newValue.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Update Hermes").font(.title2.bold())
                    Text("ContinuityPanel checks for updates whenever it opens.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Check Again") {
                    Task { await store.checkHermesUpdates() }
                }
                .disabled(store.isBusy || store.isCheckingHermesUpdate)
            }
            .padding(24)

            Divider()

            Form {
                Section("Installed") {
                    LabeledContent("Version", value: store.hermesUpdateStatus?.installedVersion ?? "Checking…")
                    if let commit = store.hermesUpdateStatus?.installedCommit {
                        LabeledContent("Revision", value: String(commit.prefix(8)))
                    }
                }

                Section("Update channel") {
                    Picker("Channel", selection: Binding(
                        get: { selectedChannel },
                        set: { selectedChannel = $0 }
                    )) {
                        ForEach(HermesUpdateChannel.allCases) { channel in
                            Text(channel.title).tag(channel)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedChannel.detail)
                        .font(.callout)
                        .foregroundStyle(selectedChannel == .latest ? .orange : .secondary)

                    if let status = store.hermesUpdateStatus {
                        channelStatus(status)
                    }
                }

                Section {
                    Label("A quick backup of Hermes configuration, sessions and credentials is created before every update. Project files are not changed.", systemImage: "externaldrive.badge.timemachine")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if !store.hermesUpdateLog.isEmpty {
                    Section("Update progress") {
                        HermesUpdateLogView(
                            text: store.hermesUpdateLog,
                            succeeded: store.hermesUpdateSucceeded
                        )
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                if store.isBusy || store.isCheckingHermesUpdate {
                    ProgressView()
                        .controlSize(.small)
                    Text(store.isBusy ? store.busyMessage : "Checking for updates…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .disabled(store.isBusy)
                Button(store.isBusy ? "Updating…" : "Update Hermes") { showingConfirmation = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canUpdate)
            }
            .padding(20)
        }
        .frame(width: 660, height: 700)
        .task {
            if store.hermesUpdateStatus == nil {
                await store.checkHermesUpdates()
            }
        }
        .alert(confirmationTitle, isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Update", role: selectedChannel == .latest ? .destructive : nil) {
                Task { _ = await store.updateHermes(channel: selectedChannel) }
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    @ViewBuilder
    private func channelStatus(_ status: HermesUpdateStatus) -> some View {
        if selectedChannel == .stable {
            LabeledContent("Newest stable release", value: status.stableTag)
            statusLabel(available: status.stableAvailable, availableText: "Stable update available")
        } else {
            LabeledContent("Newer upstream changes", value: "\(status.latestCommitsBehind)")
            statusLabel(available: status.latestAvailable, availableText: "Latest update available")
        }
    }

    private func statusLabel(available: Bool, availableText: String) -> some View {
        Label(
            available ? availableText : "Up to date on this channel",
            systemImage: available ? "arrow.down.circle.fill" : "checkmark.circle.fill"
        )
        .foregroundStyle(available ? Color.blue : Color.green)
    }

    private var canUpdate: Bool {
        guard let status = store.hermesUpdateStatus else { return false }
        return status.hasUpdate(for: selectedChannel) && !store.isBusy && !store.isCheckingHermesUpdate
    }

    private var confirmationTitle: String {
        selectedChannel == .latest ? "Install experimental Hermes code?" : "Update Hermes?"
    }

    private var confirmationMessage: String {
        if selectedChannel == .latest {
            return "Latest/Main may contain fixes not yet released, but can also introduce regressions. ContinuityPanel will back up Hermes first and restore the previous code if dependency installation fails."
        }
        return "ContinuityPanel will back up Hermes and install the newest published stable release."
    }
}

private struct HermesUpdateLogView: View {
    let text: String
    let succeeded: Bool?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                Color.clear.frame(height: 1).id("end")
            }
            .frame(minHeight: 150, maxHeight: 220)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                if let succeeded {
                    Image(systemName: succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(succeeded ? Color.green : Color.red)
                        .padding(10)
                }
            }
            .onChange(of: text) {
                withAnimation { proxy.scrollTo("end", anchor: .bottom) }
            }
        }
    }
}
