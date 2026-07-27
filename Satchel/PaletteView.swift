import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Notification names

extension Notification.Name {
    static let showStandby   = Notification.Name("satchel.showStandby")
    static let escapePalette = Notification.Name("satchel.escape")
}

// MARK: - Palette modes

private enum PaletteMode: Equatable { case rings, standby }

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

    // Evenly spaced starting at top (−π/2), clockwise in SwiftUI's y-down space.
    var angle: CGFloat {
        switch self {
        case .airdrop:  -.pi / 2
        case .messages: -.pi / 2 + 2 * .pi / 3
        case .standby:  -.pi / 2 + 4 * .pi / 3
        }
    }

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

    func activate() {
        switch self {
        case .airdrop:
            if let url = URL(string: "airdrop://") { NSWorkspace.shared.open(url) }
        case .messages:
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") {
                NSWorkspace.shared.open(url)
            }
        case .standby:
            NotificationCenter.default.post(name: .showStandby, object: nil)
        }
    }
}

// MARK: - Palette view

struct PaletteView: View {
    @Environment(PinStore.self) private var pinStore
    @State private var appeared = false
    @State private var mode: PaletteMode = .rings

    private let radius: CGFloat = 80
    private let springAnim = Animation.spring(response: 0.32, dampingFraction: 0.75)

    var body: some View {
        ZStack {
            if mode == .rings {
                ringsContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.85)),
                        removal:   .opacity.combined(with: .scale(scale: 0.85))
                    ))
            } else {
                standbyPanel
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.88)),
                        removal:   .opacity.combined(with: .scale(scale: 0.88))
                    ))
            }
        }
        .frame(width: 280, height: 280)
        .animation(springAnim, value: mode)
        .onAppear  { withAnimation { appeared = true } }
        .onDisappear { appeared = false; mode = .rings }
        .onReceive(NotificationCenter.default.publisher(for: .showStandby)) { _ in
            withAnimation(springAnim) { mode = .standby }
        }
        .onReceive(NotificationCenter.default.publisher(for: .escapePalette)) { _ in
            if mode == .standby {
                withAnimation(springAnim) { mode = .rings }
            } else {
                AppDelegate.shared?.hidePalette()
            }
        }
    }

    // MARK: - Rings

    @ViewBuilder
    private var ringsContent: some View {
        ZStack {
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
    }

    // MARK: - Standby panel

    @ViewBuilder
    private var standbyPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(springAnim) { mode = .rings }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Standby")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                // Balance chevron so title stays centered
                Image(systemName: "chevron.left").opacity(0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().opacity(0.25)

            if pinStore.items.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 26))
                        .foregroundStyle(.tertiary)
                    Text("Nothing saved yet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Drop a file onto the Standby\nring to stash it here.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 54), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(pinStore.items) { item in
                            StandbyItemView(item: item)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(width: 240, height: 240)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 20, y: 6)
    }
}
