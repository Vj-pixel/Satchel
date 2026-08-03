import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) static var shared: AppDelegate?

    var paletteWindow: PaletteWindow?
    private var eventMonitor: Any?
    private var previousApp: NSRunningApplication?
    private var isDismissing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)
        paletteWindow = PaletteWindow()
        registerHotKey()
    }

    // MARK: - Palette

    @objc func togglePalette() {
        guard let w = paletteWindow else { return }
        w.isVisible ? hidePalette() : showPalette()
    }

    func showPalette() {
        guard let w = paletteWindow else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        let m = NSEvent.mouseLocation
        let sz = w.frame.size
        w.setFrameOrigin(clamped(NSPoint(x: m.x - sz.width / 2, y: m.y - sz.height / 2), sz))
        w.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func hidePalette() {
        guard let w = paletteWindow, w.isVisible, !isDismissing else { return }
        isDismissing = true
        previousApp?.activate()
        previousApp = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            w.animator().alphaValue = 0
        }) { [weak self] in
            w.orderOut(nil)
            w.alphaValue = 1
            self?.isDismissing = false
        }
    }

    private func clamped(_ pt: NSPoint, _ sz: NSSize) -> NSPoint {
        guard let f = NSScreen.main?.visibleFrame else { return pt }
        return NSPoint(
            x: max(f.minX, min(pt.x, f.maxX - sz.width)),
            y: max(f.minY, min(pt.y, f.maxY - sz.height))
        )
    }

    // MARK: - Global hotkey

    func reregisterHotKey() {
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
        registerHotKey()
    }

    private func registerHotKey() {
        if !AXIsProcessTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            AXIsProcessTrustedWithOptions(opts as CFDictionary)
        }
        let cfg = HotkeyStore.shared.config
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard event.keyCode == cfg.keyCode, flags == cfg.modifiers else { return }
            DispatchQueue.main.async { AppDelegate.shared?.togglePalette() }
        }
    }
}
