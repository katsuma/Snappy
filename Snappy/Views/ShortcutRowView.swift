import SwiftUI

struct ShortcutRowView: View {
    @Binding var shortcut: Shortcut

    var body: some View {
        HStack(spacing: 16) {
            TextField("Name", text: $shortcut.name)
                .textFieldStyle(.plain)
                .frame(minWidth: 100, maxWidth: 140)

            GridPickerView(region: $shortcut.gridRegion)

            Spacer()

            KeyRecorderView(keyCombo: $shortcut.keyCombo)
                .frame(width: 120, height: 26)
        }
        .padding(.vertical, 4)
    }
}
