import SwiftUI
import UniformTypeIdentifiers

// MARK: - Action ring

struct ActionRingView: View {
    let action: SatchelAction
    @Environment(AppearanceStore.self) private var appearance
    @State private var isHovered = false
    @State private var isTargeted = false
    @State private var bounced = false

    var body: some View {
        VStack(spacing: 5) {
            ring
            Text(action.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.85))
                .shadow(color: .black.opacity(0.55), radius: 2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: appearance.ringSize.diameter + 12)
        }
        .onHover { isHovered = $0 }
        .onTapGesture { action.activate() }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
    }

    private var ring: some View {
        let d = appearance.ringSize.diameter
        let iconPt = appearance.ringSize.iconSize

        return ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(action.tint.opacity(isTargeted ? 0.28 : isHovered ? 0.14 : 0.06))
            Circle().strokeBorder(
                isTargeted ? action.tint : Color.white.opacity(0.22),
                lineWidth: isTargeted ? 2 : 0.5
            )
            Image(systemName: action.icon)
                .font(.system(size: iconPt, weight: .medium))
                .foregroundStyle(isTargeted ? action.tint : Color.primary.opacity(0.75))
                .symbolEffect(.bounce, value: bounced)
        }
        .frame(width: d, height: d)
        .shadow(
            color: action.tint.opacity(isTargeted ? 0.45 : 0.12),
            radius: isTargeted ? 14 : 6,
            y: 3
        )
        .scaleEffect(isHovered ? 1.1 : isTargeted ? 1.06 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isTargeted)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for p in providers {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in
                    action.perform(with: url)
                    bounced = true
                    try? await Task.sleep(for: .milliseconds(400))
                    AppDelegate.shared?.hidePalette()
                }
            }
        }
        return true
    }
}

// MARK: - Standby item cell

struct StandbyItemView: View {
    let item: PinnedItem
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.12 : 0.06))
                Image(nsImage: item.icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 30, height: 30)
            }
            .frame(width: 48, height: 48)

            Text(item.name)
                .font(.system(size: 9))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.opacity(0.75))
                .frame(maxWidth: 52)
        }
        .onHover { isHovered = $0 }
        .onTapGesture {
            NSWorkspace.shared.open(item.url)
            AppDelegate.shared?.hidePalette()
        }
        .contextMenu {
            Button(role: .destructive) {
                PinStore.shared.remove(id: item.id)
            } label: {
                Label("Remove from Satchel", systemImage: "trash")
            }
        }
        .scaleEffect(isHovered ? 1.06 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
    }
}
