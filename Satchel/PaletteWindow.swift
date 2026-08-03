import AppKit
import SwiftUI

final class PaletteWindow: NSPanel {
    init() {
        // 380×380 accommodates 6 rings at all three size presets.
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 380),
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

        let root = PaletteView()
            .environment(PinStore.shared)
            .environment(AppearanceStore.shared)
        contentView = NSHostingView(rootView: root)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            NotificationCenter.default.post(name: .escapePalette, object: nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
