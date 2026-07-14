import AppKit
import Foundation

@MainActor
enum ProjectFolderPicker {
    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a project to import"
        panel.prompt = "Choose Project"
        panel.message = "ContinuityPanel will copy this folder. The original will remain unchanged."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true
        return panel.runModal() == .OK ? panel.url : nil
    }
}
