import SwiftUI
import ServiceManagement

struct GeneralView: View {
    @State private var accessibilityGranted = false
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("Accessibility") {
                if accessibilityGranted {
                    Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Accessibility access required", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Snappy needs accessibility permission to move and resize windows.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Open System Settings\u{2026}") {
                            openAccessibilitySettings()
                        }
                    }
                }
            }

            Section("Login") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
            }
        }
        .formStyle(.grouped)
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
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail - user can retry
        }
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
