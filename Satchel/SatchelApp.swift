import SwiftUI

@main
struct SatchelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No regular window — everything lives in the palette and menu bar.
        Settings { EmptyView() }
    }
}
