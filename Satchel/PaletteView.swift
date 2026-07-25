import SwiftUI
import UniformTypeIdentifiers

struct PaletteView: View {
    @EnvironmentObject var store: PinStore
    @State private var isTargeted = false

    private let cols = Array(repeating: GridItem(.fixed(68), spacing: 6), count: 4)

    var body: some View {
        ZStack {
            VisualEffect(material: .hudWindow, blending: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)

            VStack(spacing: 0) {
                header
                Divider().opacity(0.3)
                if store.items.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
        }
        .frame(width: 316)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handlePaletteDrop)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .opacity(isTargeted ? 1 : 0)
                .animation(.easeInOut(duration: 0.12), value: isTargeted)
        )
    }

    private var header: some View {
        HStack {
            Text("Satchel")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text("⌥Space")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.06))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var grid: some View {
        LazyVGrid(columns: cols, spacing: 6) {
            ForEach(store.items) { item in
                PinnedItemView(item: item)
                    .environmentObject(store)
            }
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 30))
                .foregroundStyle(.quaternary)
            Text("Drop anything here")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Apps · Folders · Files")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func handlePaletteDrop(_ providers: [NSItemProvider]) -> Bool {
        for p in providers {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { self.store.add(url: url) }
            }
        }
        return true
    }
}

// NSVisualEffectView bridge for the frosted-glass background
struct VisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blending: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .active
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}
