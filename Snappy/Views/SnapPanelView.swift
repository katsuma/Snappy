import SwiftUI
import AppKit

struct SnapPanelView: View {
    let targetApp: NSRunningApplication
    let onSelect: (GridRegion) -> Void
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    @State private var region: GridRegion? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 8) {
                    if let icon = targetApp.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                    Text(targetApp.localizedName ?? "")
                        .font(.headline)
                }

                Spacer()

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()
                .opacity(0.3)

            // Grid
            VStack(spacing: 12) {
                GridPickerView(region: $region, cellSize: 58, onCommit: onSelect)
                Text("Drag to select · Esc to cancel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}
