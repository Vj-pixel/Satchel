import AppKit
import SwiftUI

final class PaletteWindow: NSPanel {
    init() {
        // 260×260 fits radius=90 ring + 60pt items with padding.
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 280),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isMovableByWindowBackground = false
        level = .floating
        backgroundColor = .clear
        hasShadow = false
        isOpaque = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let root = PaletteView().environment(PinStore.shared)
        contentView = NSHostingView(rootView: root)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
