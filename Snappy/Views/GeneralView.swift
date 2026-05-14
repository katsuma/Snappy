import SwiftUI
import ServiceManagement

struct GeneralView: View {
    @EnvironmentObject var settings: PanelSettings
    @State private var accessibilityGranted = false
    @State private var launchAtLogin = false
    @State private var pollTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Accessibility section
                GlassEffectContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Accessibility", systemImage: "accessibility")
                            .font(.headline)

                        Divider()

                        if accessibilityGranted {
                            Label("Access granted", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Access required to move windows", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Button("Open System Settings\u{2026}") {
                                    openAccessibilitySettings()
                                }
                                .buttonStyle(.glassProminent)
                            }
                        }
                    }
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }

                // Login section
                GlassEffectContainer {
                    HStack {
                        Label("Launch at Login", systemImage: "power")
                        Spacer()
                        Toggle("", isOn: $launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: launchAtLogin) { _, enabled in
                                setLaunchAtLogin(enabled)
                            }
                    }
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }

                // Panel hotkey section
                GlassEffectContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Panel", systemImage: "rectangle.on.rectangle")
                            .font(.headline)

                        Divider()

                        HStack {
                            Text("Use global shortcut to open panel")
                            Spacer()
                            Toggle("", isOn: $settings.useGlobalHotkey)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        if settings.useGlobalHotkey {
                            HStack {
                                Text("Shortcut")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                KeyRecorderView(keyCombo: $settings.openPanelCombo)
                                    .frame(width: 140, height: 26)
                            }
                        }
                    }
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            refresh()
            pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                DispatchQueue.main.async { accessibilityGranted = AXIsProcessTrusted() }
            }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        } catch {
            // Silently ignore — fails when running from DerivedData
        }
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
