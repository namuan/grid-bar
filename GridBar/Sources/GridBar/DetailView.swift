import SwiftUI

struct DetailView: View {
    let item: MenuBarItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.escape)
            }

            Image(nsImage: item.appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            Text(item.ownerName)
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                row("Bundle ID", item.bundleIdentifier)
                row("PID", "\(item.pid)")
                row("Type", item.isSystemItem ? "System" : "Third-party")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button("Bring to Front") {
                NSRunningApplication(processIdentifier: item.pid)?.activate()
            }
            .disabled(item.isSystemItem)
        }
        .padding(32)
        .frame(minWidth: 320)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
                .monospaced()
        }
        .font(.callout)
    }
}
