import AppKit

struct PinnedItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let icon: NSImage
    let kind: Kind

    enum Kind { case app, folder, file }

    init(url: URL) {
        self.url = url
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

        if url.pathExtension.lowercased() == "app" {
            kind = .app
            name = url.deletingPathExtension().lastPathComponent
        } else if isDir.boolValue {
            kind = .folder
            name = url.lastPathComponent
        } else {
            kind = .file
            name = url.lastPathComponent
        }
        icon = NSWorkspace.shared.icon(forFile: url.path)
    }
}
