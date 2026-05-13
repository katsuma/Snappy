import SwiftUI

struct ShortcutsView: View {
    @EnvironmentObject var store: ShortcutStore

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $store.selectedID) {
                ForEach($store.shortcuts) { $shortcut in
                    ShortcutRowView(shortcut: $shortcut)
                        .tag(shortcut.id)
                }
            }
            .listStyle(.inset)

            Divider()

            HStack {
                Button("New") {
                    store.addShortcut()
                }
                Spacer()
                Button("Delete") {
                    if let id = store.selectedID {
                        store.deleteShortcut(id: id)
                    }
                }
                .disabled(store.selectedID == nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
