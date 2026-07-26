import SwiftUI
import UniformTypeIdentifiers

struct ActionRingView: View {
    let action: SatchelAction
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
        }
        .onHover { isHovered = $0 }
        .onTapGesture { action.activate() }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
    }

    private var ring: some View {
        ZStack {
            // Frosted glass base
            Circle()
                .fill(.ultraThinMaterial)

            // Tint fill that intensifies on hover / targeting
            Circle()
                .fill(action.tint.opacity(isTargeted ? 0.28 : isHovered ? 0.14 : 0.06))

            // Border
            Circle()
                .strokeBorder(
                    isTargeted ? action.tint : Color.white.opacity(0.22),
                    lineWidth: isTargeted ? 2 : 0.5
                )

            // Icon
            Image(systemName: action.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(isTargeted ? action.tint : Color.primary.opacity(0.75))
                .symbolEffect(.bounce, value: bounced)
        }
        .frame(width: 72, height: 72)
        .shadow(
            color: action.tint.opacity(isTargeted ? 0.45 : 0.12),
            radius: isTargeted ? 14 : 6,
            y: 3
        )
        .scaleEffect(isHovered ? 1.1 : isTargeted ? 1.06 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isTargeted)
    }

    // MARK: - Drop

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
