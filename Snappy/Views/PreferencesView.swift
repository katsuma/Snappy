import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var settings: PanelSettings

    var body: some View {
        TabView {
            GeneralView()
                .tabItem { Label("General", systemImage: "gear") }
            HotkeyView()
                .tabItem { Label("Hotkey", systemImage: "keyboard") }
        }
        .frame(width: 560, height: 440)
        .padding(.top, 28)
    }
}
