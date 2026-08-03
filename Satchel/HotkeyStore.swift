import AppKit
import Observation

struct HotkeyConfig: Codable {
    var keyCode: UInt16 = 49  // Space
    var modifierRaw: UInt = NSEvent.ModifierFlags([.control, .option]).rawValue  // ⌃⌥Space

    static let `default` = HotkeyConfig()

    var modifiers: NSEvent.ModifierFlags { .init(rawValue: modifierRaw) }

    var displayString: String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option)  { s += "⌥" }
        if modifiers.contains(.shift)   { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        s += keyName
        return s
    }

    var keyName: String {
        switch keyCode {
        case 49:  return "Space"
        case 36:  return "↩"
        case 48:  return "⇥"
        case 51:  return "⌫"
        case 53:  return "Esc"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            let map: [UInt16: String] = [
                0:"A",1:"S",2:"D",3:"F",4:"H",5:"G",6:"Z",7:"X",8:"C",9:"V",
                11:"B",12:"Q",13:"W",14:"E",15:"R",16:"Y",17:"T",
                18:"1",19:"2",20:"3",21:"4",22:"6",23:"5",
                24:"=",25:"9",26:"7",27:"-",28:"8",29:"0",
                30:"]",31:"O",32:"U",33:"[",34:"I",35:"P",
                37:"L",38:"J",39:"'",40:"K",41:";",42:"\\",
                43:",",44:"/",45:"N",46:"M",47:".",50:"`"
            ]
            return map[keyCode] ?? "?"
        }
    }
}

@MainActor
@Observable
final class HotkeyStore {
    static let shared = HotkeyStore()

    private(set) var config: HotkeyConfig

    private init() {
        if let data = UserDefaults.standard.data(forKey: "satchel.hotkey"),
           let saved = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            config = saved
        } else {
            config = .default
        }
    }

    func updateConfig(_ new: HotkeyConfig) {
        config = new
        if let data = try? JSONEncoder().encode(new) {
            UserDefaults.standard.set(data, forKey: "satchel.hotkey")
        }
        AppDelegate.shared?.reregisterHotKey()
    }
}
