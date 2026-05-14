import SwiftUI
import AppKit

struct SnapPanelView: View {
    let targetApp: NSRunningApplication
    let onSelect: (GridRegion) -> Void

    @State private var region: GridRegion? = nil

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                if let icon = targetApp.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 36, height: 36)
                }
                Text(targetApp.localizedName ?? "")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            GridPickerView(region: $region, cellSize: 58, onCommit: onSelect)

            Text("Drag to select · Esc to cancel")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }
}
