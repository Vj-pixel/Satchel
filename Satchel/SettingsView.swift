import SwiftUI

struct SettingsView: View {
    @Environment(HotkeyStore.self) var hotkeyStore
    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                LabeledContent("Invoke Satchel") {
                    hotkeyField
                }
            }

            Section("Pinned Items") {
                pinList
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 320)
    }

    // MARK: - Hotkey recorder

    private var hotkeyField: some View {
        HStack(spacing: 8) {
            Button(action: toggleRecording) {
                Text(isRecording ? "Press keys…" : hotkeyStore.config.displayString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRecording ? Color.accentColor : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        isRecording ? Color.accentColor : Color.primary.opacity(0.14),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .buttonStyle(.plain)

            if isRecording {
                Button("Cancel") { stopRecording() }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Pin list

    @ViewBuilder
    private var pinList: some View {
        let items = PinStore.shared.items
        if items.isEmpty {
            Text("No pins yet — press ⌥Space and drag anything onto the palette.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        } else {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 18, height: 18)
                    Text(item.name)
                        .font(.system(size: 12))
                    Spacer()
                    Button(role: .destructive) {
                        PinStore.shared.remove(id: item.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recording logic

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape — cancel
                self.stopRecording()
                return nil
            }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !flags.isEmpty else { return nil } // require at least one modifier
            let newCfg = HotkeyConfig(keyCode: event.keyCode, modifierRaw: flags.rawValue)
            self.hotkeyStore.updateConfig(newCfg)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }
}
