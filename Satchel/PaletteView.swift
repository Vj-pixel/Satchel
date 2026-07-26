import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Action model

enum SatchelAction: CaseIterable, Identifiable {
    case airdrop, messages, standby

    var id: Self { self }

    var label: String {
        switch self {
        case .airdrop:  "AirDrop"
        case .messages: "Messages"
        case .standby:  "Standby"
        }
    }

    var icon: String {
        switch self {
        case .airdrop:  "wifi"
        case .messages: "message.fill"
        case .standby:  "tray.fill"
        }
    }

    var tint: Color {
        switch self {
        case .airdrop:  .blue
        case .messages: .green
        case .standby:  .orange
        }
    }

    // Evenly spaced, starting at top (−π/2) going clockwise in SwiftUI's y-down space.
    var angle: CGFloat {
        switch self {
        case .airdrop:  -.pi / 2                 // 12 o'clock
        case .messages: -.pi / 2 + 2 * .pi / 3  // 4 o'clock  (lower-right)
        case .standby:  -.pi / 2 + 4 * .pi / 3  // 8 o'clock  (lower-left)
        }
    }

    // Called when a file is dropped on the ring.
    func perform(with url: URL) {
        switch self {
        case .airdrop:
            NSSharingService(named: .sendViaAirDrop)?.perform(withItems: [url])
        case .messages:
            NSSharingService(named: .composeMessage)?.perform(withItems: [url])
        case .standby:
            Task { @MainActor in PinStore.shared.add(url: url) }
        }
    }

    // Called on a bare tap (no file).
    func activate() {
        switch self {
        case .airdrop:
            if let url = URL(string: "airdrop://") { NSWorkspace.shared.open(url) }
        case .messages:
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") {
                NSWorkspace.shared.open(url)
            }
        case .standby:
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Palette view

struct PaletteView: View {
    @State private var appeared = false

    private let radius: CGFloat = 80

    var body: some View {
        ZStack {
            // Tiny center pip marks the cursor anchor point.
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.35), radius: 4)

            ForEach(Array(SatchelAction.allCases.enumerated()), id: \.element.id) { i, action in
                ActionRingView(action: action)
                    .offset(
                        x: appeared ? radius * cos(action.angle) : 0,
                        y: appeared ? radius * sin(action.angle) : 0
                    )
                    .scaleEffect(appeared ? 1 : 0.05)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.32, dampingFraction: 0.66).delay(Double(i) * 0.06),
                        value: appeared
                    )
            }
        }
        .frame(width: 280, height: 280)
        .onAppear { withAnimation { appeared = true } }
        .onDisappear { appeared = false }
    }
}
