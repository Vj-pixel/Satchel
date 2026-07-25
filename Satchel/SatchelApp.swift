import SwiftUI

@main
struct SatchelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar icon + dropdown — no Dock icon (LSUIElement handles that)
        MenuBarExtra("Satchel", systemImage: "bag.fill") {
            Button("Open Palette") {
                AppDelegate.shared?.togglePalette()
            }
            Divider()
            SettingsLink()
            Divider()
            Button("Quit Satchel") { NSApp.terminate(nil) }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(HotkeyStore.shared)
                .environment(PinStore.shared)
        }
    }
}
