import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var store: ShortcutStore

    var body: some View {
        TabView {
            GeneralView()
                .tabItem { Label("General", systemImage: "gear") }
            ShortcutsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 560, height: 440)
        .padding(.top, 28)  // account for transparent title bar
    }
}
