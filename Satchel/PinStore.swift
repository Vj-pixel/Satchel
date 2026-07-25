import AppKit
import Combine

@MainActor
final class PinStore: ObservableObject {
    static let shared = PinStore()

    @Published private(set) var items: [PinnedItem] = []

    private init() { load() }

    func add(url: URL) {
        guard !items.contains(where: { $0.url == url }) else { return }
        items.append(PinnedItem(url: url))
        save()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    private func save() {
        UserDefaults.standard.set(items.map(\.url.path), forKey: "satchel.pins")
    }

    private func load() {
        items = (UserDefaults.standard.stringArray(forKey: "satchel.pins") ?? [])
            .filter { FileManager.default.fileExists(atPath: $0) }
            .map { PinnedItem(url: URL(fileURLWithPath: $0)) }
    }
}
