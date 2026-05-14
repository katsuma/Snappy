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
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 6) {
                    if let icon = targetApp.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 22, height: 22)
                    }
                    Text(targetApp.localizedName ?? "")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.3)

            // Grid
            VStack(spacing: 8) {
                GridPickerView(region: $region, cellSize: 44, onCommit: onSelect)
                Text("Drag to select · Esc to cancel")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
        }
    }
}
