import SwiftUI

@main
struct SatchelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(HotkeyStore.shared)
                .environment(PinStore.shared)
        }
    }
}
