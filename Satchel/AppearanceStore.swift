import Foundation
import Observation

enum RingSize: String, CaseIterable, Codable {
    case small, medium, large

    var label: String { rawValue.capitalized }

    var diameter: CGFloat {
        switch self { case .small: 56; case .medium: 72; case .large: 88 }
    }

    // Orbit radius from center of palette to center of ring
    var radius: CGFloat {
        switch self { case .small: 88; case .medium: 105; case .large: 120 }
    }

    var iconSize: CGFloat {
        switch self { case .small: 20; case .medium: 28; case .large: 36 }
    }
}

@MainActor
@Observable
final class AppearanceStore {
    static let shared = AppearanceStore()

    private(set) var ringSize: RingSize = .medium

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "satchel.ringSize"),
           let saved = RingSize(rawValue: raw) {
            ringSize = saved
        }
    }

    func setRingSize(_ size: RingSize) {
        ringSize = size
        UserDefaults.standard.set(size.rawValue, forKey: "satchel.ringSize")
    }
}
