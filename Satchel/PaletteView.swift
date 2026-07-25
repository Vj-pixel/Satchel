import SwiftUI
import UniformTypeIdentifiers

struct PaletteView: View {
    @Environment(PinStore.self) var store
    @State private var appeared = false
    @State private var dropTargeted = false

    private let radius: CGFloat = 90
    private let itemSize: CGFloat = 60

    var body: some View {
        ZStack {
            // Transparent full-area drop zone (adds new pins)
            Color.clear
                .onDrop(of: [.fileURL], isTargeted: $dropTargeted, perform: handleDrop)

            // Subtle drop-target ring
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(width: radius * 2 + 8, height: radius * 2 + 8)
                .opacity(dropTargeted ? 1 : 0)
                .animation(.easeInOut(duration: 0.12), value: dropTargeted)

            // Center pip — anchors the eye at the cursor position
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.3), radius: 4)

            if store.items.isEmpty {
                emptyRing
            } else {
                radialItems
            }
        }
        .frame(width: 260, height: 260)
        .onAppear {
            withAnimation { appeared = true }
        }
        .onDisappear {
            appeared = false
        }
    }

    // MARK: - Radial items

    private var radialItems: some View {
        ForEach(Array(store.items.enumerated()), id: \.element.id) { i, item in
            let angle = radialAngle(i, of: store.items.count)
            RadialItemView(item: item)
                .offset(
                    x: appeared ? radius * cos(angle) : 0,
                    y: appeared ? radius * sin(angle) : 0
                )
                .scaleEffect(appeared ? 1 : 0.1)
                .opacity(appeared ? 1 : 0)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.68)
                    .delay(Double(i) * 0.04),
                    value: appeared
                )
        }
    }

    // MARK: - Empty state (dashed ghost circles)

    private var emptyRing: some View {
        Group {
            ForEach(0..<4, id: \.self) { i in
                let angle = radialAngle(i, of: 4)
                Circle()
                    .strokeBorder(
                        Color.primary.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
                    .frame(width: itemSize, height: itemSize)
                    .offset(
                        x: appeared ? radius * cos(angle) : 0,
                        y: appeared ? radius * sin(angle) : 0
                    )
                    .scaleEffect(appeared ? 1 : 0.1)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.68)
                        .delay(Double(i) * 0.04),
                        value: appeared
                    )
            }

            VStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Drop to pin")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.tertiary)
            .shadow(color: .black.opacity(0.5), radius: 2)
        }
    }

    // MARK: - Helpers

    // Starts at the top (−π/2) and goes clockwise.
    // In SwiftUI (y-down), increasing angle is visually clockwise.
    private func radialAngle(_ i: Int, of total: Int) -> CGFloat {
        (2 * .pi / CGFloat(max(total, 1))) * CGFloat(i) - .pi / 2
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for p in providers {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in self.store.add(url: url) }
            }
        }
        return true
    }
}
