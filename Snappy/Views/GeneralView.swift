import SwiftUI
import ServiceManagement

struct GeneralView: View {
    @State private var accessibilityGranted = false
    @State private var launchAtLogin = false

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
                                .buttonStyle(.glass)
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
                            .onChange(of: launchAtLogin) { _, enabled in
                                setLaunchAtLogin(enabled)
                            }
                    }
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
    }

    private func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
