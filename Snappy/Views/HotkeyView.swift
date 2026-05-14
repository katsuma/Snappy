import SwiftUI

struct HotkeyView: View {
    @EnvironmentObject var settings: PanelSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                GlassEffectContainer {
                    HStack {
                        Label("Open Panel", systemImage: "rectangle.on.rectangle")
                        Spacer()
                        KeyRecorderView(keyCombo: $settings.openPanelCombo)
                            .frame(width: 140, height: 26)
                    }
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
    }
}
