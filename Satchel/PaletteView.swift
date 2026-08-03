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
    case airdrop, messages, mail, copy, finder, standby

    var id: Self { self }

    var label: String {
        switch self {
        case .airdrop:  "AirDrop"
        case .messages: "Messages"
        case .mail:     "Mail"
        case .copy:     "Copy"
        case .finder:   "Finder"
        case .standby:  "Your Satchel"
        }
    }

    var icon: String {
        switch self {
        case .airdrop:  "wifi"
        case .messages: "message.fill"
        case .mail:     "envelope.fill"
        case .copy:     "doc.on.doc.fill"
        case .finder:   "folder.fill"
        case .standby:  "tray.fill"
        }
    }

    var tint: Color {
        switch self {
        case .airdrop:  .blue
        case .messages: .green
        case .mail:     .indigo
        case .copy:     .teal
        case .finder:   .yellow
        case .standby:  .orange
        }
    }

    // Evenly distributed starting at 12 o'clock, clockwise in SwiftUI y-down space.
    var angle: CGFloat {
        let all = SatchelAction.allCases
        guard let i = all.firstIndex(of: self) else { return 0 }
        return (2 * .pi / CGFloat(all.count)) * CGFloat(i) - .pi / 2
    }

    func perform(with url: URL) {
        switch self {
        case .airdrop:
            NSSharingService(named: .sendViaAirDrop)?.perform(withItems: [url])
        case .messages:
            NSSharingService(named: .composeMessage)?.perform(withItems: [url])
        case .mail:
            NSSharingService(named: .composeEmail)?.perform(withItems: [url])
        case .copy:
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.writeObjects([url as NSURL])
        case .finder:
            NSWorkspace.shared.activateFileViewerSelecting([url])
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
        case .mail:
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.mail") {
                NSWorkspace.shared.open(url)
            }
        case .copy:
            break
        case .finder:
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser)
        case .standby:
            NotificationCenter.default.post(name: .showStandby, object: nil)
        }
    }
}

// MARK: - Palette view

struct PaletteView: View {
    @Environment(PinStore.self) private var pinStore
    @Environment(AppearanceStore.self) private var appearance
    @State private var appeared = false
    @State private var mode: PaletteMode = .rings

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
        .frame(width: 380, height: 380)
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
            // Center pip pops in first before petals bloom
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.35), radius: 4)
                .scaleEffect(appeared ? 1 : 0.01)
                .animation(.spring(response: 0.22, dampingFraction: 0.58), value: appeared)

            ForEach(Array(SatchelAction.allCases.enumerated()), id: \.element.id) { i, action in
                ActionRingView(action: action)
                    .offset(
                        x: appeared ? appearance.ringSize.radius * cos(action.angle) : 0,
                        y: appeared ? appearance.ringSize.radius * sin(action.angle) : 0
                    )
                    .scaleEffect(appeared ? 1 : 0.01)
                    .opacity(appeared ? 1 : 0)
                    // Bouncy spring + sequential stagger = flower bloom feel
                    .animation(
                        .spring(response: 0.38, dampingFraction: 0.52)
                            .delay(0.06 + Double(i) * 0.07),
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

                Text("Your Satchel")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.left").opacity(0) // balance
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
                    Text("Drop a file onto the\nYour Satchel ring to stash it here.")
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
        .frame(width: 260, height: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 20, y: 6)
    }
}
