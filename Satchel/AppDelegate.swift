import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
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
        btn.action = #selector(showStatusMenu)
        btn.target = self
    }

    @objc private func showStatusMenu() {
        let menu = NSMenu()

        let invoke = NSMenuItem(title: "Open Palette", action: #selector(togglePalette), keyEquivalent: "")
        invoke.target = self
        menu.addItem(invoke)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit Satchel", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Palette

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

    // MARK: - Auto-dismiss on focus loss

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
