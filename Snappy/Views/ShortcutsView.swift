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
            .scrollContentBackground(.hidden)

            Divider()
                .opacity(0.3)

            HStack {
                Button("New") {
                    store.addShortcut()
                }
                .buttonStyle(.glass)

                Spacer()

                Button("Delete") {
                    if let id = store.selectedID {
                        store.deleteShortcut(id: id)
                    }
                }
                .buttonStyle(.glass)
                .disabled(store.selectedID == nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}
