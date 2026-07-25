import SwiftUI
import UniformTypeIdentifiers

struct PinnedItemView: View {
    let item: PinnedItem
    @EnvironmentObject var store: PinStore
    @State private var isTargeted = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .scaleEffect(isHovered ? 1.08 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isHovered)

            Text(item.name)
                .font(.system(size: 9.5))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
        .frame(width: 68, height: 78)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isTargeted ? Color.accentColor : .clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { NSWorkspace.shared.open(item.url) }
        .contextMenu { contextItems }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
    }

    private var bgColor: Color {
        if isTargeted { return Color.accentColor.opacity(0.14) }
        if isHovered  { return Color.primary.opacity(0.07) }
        return .clear
    }

    @ViewBuilder
    private var contextItems: some View {
        Button {
            NSWorkspace.shared.open(item.url)
        } label: {
            Label(item.kind == .app ? "Launch" : "Open", systemImage: openIcon)
        }
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
        } label: {
            Label("Reveal in Finder", systemImage: "folder")
        }
        Divider()
        Button(role: .destructive) {
            store.remove(id: item.id)
        } label: {
            Label("Remove from Satchel", systemImage: "minus.circle")
        }
    }

    private var openIcon: String {
        switch item.kind {
        case .app:    "play.circle"
        case .folder: "folder.fill"
        case .file:   "doc.fill"
        }
    }

    // MARK: - Drop handling

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for p in providers {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { self.performDrop(url: url) }
            }
        }
        return true
    }

    private func performDrop(url: URL) {
        switch item.kind {
        case .folder:
            // Move the dropped file into this folder
            let dest = item.url.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.moveItem(at: url, to: dest)
        case .app:
            // Open the dropped file with this app
            NSWorkspace.shared.open(
                [url], withApplicationAt: item.url,
                configuration: .init(), completionHandler: nil
            )
        case .file:
            NSWorkspace.shared.open(url)
        }
    }
}
