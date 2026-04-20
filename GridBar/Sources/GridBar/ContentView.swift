import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = MenuBarScanner()
    @State private var selectedItem: MenuBarItem?
    let columns = [GridItem(.adaptive(minimum: 90, maximum: 110), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if scanner.items.isEmpty && !scanner.isScanning {
                emptyState
            } else {
                itemGrid
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            scanner.scan()
            Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                scanner.scan()
            }
        }
        .sheet(item: $selectedItem) { item in
            DetailView(item: item)
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Menu Bar Apps")
                .font(.title2)
                .fontWeight(.bold)
            if scanner.isScanning {
                ProgressView().scaleEffect(0.7).padding(.leading, 4)
            }
            Spacer()
            Text("\(scanner.items.count) items")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button {
                scanner.scan()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r")
            .disabled(scanner.isScanning)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No menu bar apps found")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Scan Now") { scanner.scan() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(scanner.items) { item in
                    itemCell(item)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func itemCell(_ item: MenuBarItem) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: item.appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )

            Text(item.ownerName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 90)
        }
        .padding(6)
        .contentShape(Rectangle())
        .onTapGesture { MenuBarActivator.activate(item) }
        .contextMenu {
            Button("Show Info") { selectedItem = item }
            Divider()
            Button("Activate App") {
                NSRunningApplication(processIdentifier: item.pid)?
                    .activate(options: .activateIgnoringOtherApps)
            }
        }
        .help(item.ownerName)
    }
}
