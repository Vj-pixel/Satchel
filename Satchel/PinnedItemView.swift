import SwiftUI
import UniformTypeIdentifiers

// Each pin in the radial ring is a frosted-glass circle with an icon.
struct RadialItemView: View {
    let item: PinnedItem
    @Environment(PinStore.self) var store
    @State private var isHovered = false
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 4) {
            circle
            label
        }
        .onTapGesture { NSWorkspace.shared.open(item.url) }
        .contextMenu { contextItems }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
    }

    // MARK: - Subviews

    private var circle: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isTargeted ? Color.accentColor : Color.white.opacity(0.2),
                            lineWidth: isTargeted ? 2 : 0.5
                        )
                )
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)

            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 34, height: 34)
        }
        .frame(width: 60, height: 60)
        .scaleEffect(isHovered ? 1.12 : isTargeted ? 1.06 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isTargeted)
        .onHover { isHovered = $0 }
    }

    private var label: some View {
        Text(item.name)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .frame(maxWidth: 72)
            .shadow(color: .black.opacity(0.6), radius: 2)
    }

    // MARK: - Context menu

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
                Task { @MainActor in self.performDrop(url: url) }
            }
        }
        return true
    }

    private func performDrop(url: URL) {
        switch item.kind {
        case .folder:
            let dest = item.url.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.moveItem(at: url, to: dest)
        case .app:
            NSWorkspace.shared.open(
                [url], withApplicationAt: item.url,
                configuration: .init(), completionHandler: nil
            )
        case .file:
            NSWorkspace.shared.open(url)
        }
    }
}
