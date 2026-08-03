import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(HotkeyStore.self) var hotkeyStore
    @Environment(AppearanceStore.self) var appearance
    @State private var isRecording = false
    @State private var localMonitor: Any?
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var accessibilityGranted = AXIsProcessTrusted()

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue { try SMAppService.mainApp.register() }
                            else { try SMAppService.mainApp.unregister() }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section("Appearance") {
                LabeledContent("Ring Size") {
                    Picker("", selection: Binding(
                        get: { appearance.ringSize },
                        set: { appearance.setRingSize($0) }
                    )) {
                        ForEach(RingSize.allCases, id: \.self) { size in
                            Text(size.label).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }

            Section("Keyboard Shortcut") {
                LabeledContent("Invoke Satchel") {
                    hotkeyField
                }
            }

            Section("Permissions") {
                HStack(spacing: 8) {
                    Image(systemName: accessibilityGranted
                          ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(accessibilityGranted ? .green : .orange)
                    Text(accessibilityGranted
                         ? "Accessibility access granted"
                         : "Accessibility access required for global hotkey")
                        .font(.system(size: 12))
                    Spacer()
                    if !accessibilityGranted {
                        Button("Open Settings") {
                            NSWorkspace.shared.open(
                                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onAppear { accessibilityGranted = AXIsProcessTrusted() }
            }

            Section("Your Satchel") {
                pinList
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 460)
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
            Text("Nothing in Your Satchel yet — press ⌃⌥Space and drop a file onto the Satchel ring.")
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
            guard !flags.isEmpty else { return nil }
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
