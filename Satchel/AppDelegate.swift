import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // nonisolated(unsafe) so the event-monitor block (non-isolated) can reach us.
    nonisolated(unsafe) static var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    var paletteWindow: PaletteWindow?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        paletteWindow = PaletteWindow()
        setupDismiss()
        registerHotKey()
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let btn = statusItem?.button else { return }
        btn.image = NSImage(systemSymbolName: "bag.fill", accessibilityDescription: "Satchel")
        btn.action = #selector(togglePalette)
        btn.target = self
    }

    // MARK: - Palette visibility

    @objc func togglePalette() {
        guard let w = paletteWindow else { return }
        w.isVisible ? hidePalette() : showPalette()
    }

    func showPalette() {
        guard let w = paletteWindow else { return }
        let m = NSEvent.mouseLocation
        let sz = w.frame.size
        w.setFrameOrigin(clamped(NSPoint(x: m.x - sz.width / 2, y: m.y - sz.height / 2), sz))
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePalette() {
        paletteWindow?.orderOut(nil)
    }

    private func clamped(_ pt: NSPoint, _ sz: NSSize) -> NSPoint {
        guard let f = NSScreen.main?.visibleFrame else { return pt }
        return NSPoint(
            x: max(f.minX, min(pt.x, f.maxX - sz.width)),
            y: max(f.minY, min(pt.y, f.maxY - sz.height))
        )
    }

    // MARK: - Auto-dismiss when palette loses focus

    private func setupDismiss() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, note.object as? NSWindow === self.paletteWindow else { return }
            self.hidePalette()
        }
    }

    // MARK: - Global hotkey ⌥Space

    private func registerHotKey() {
        // Prompt for Accessibility permission if not already granted.
        // macOS requires it for apps to monitor global key events.
        if !AXIsProcessTrusted() {
            let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            AXIsProcessTrustedWithOptions(opts as CFDictionary)
        }

        // kVK_Space = 49 (Carbon constant, used as raw value here)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let optionOnly = event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option
            guard event.keyCode == 49, optionOnly else { return }
            DispatchQueue.main.async { AppDelegate.shared?.togglePalette() }
        }
    }
}
