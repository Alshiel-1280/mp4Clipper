import AVKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @StateObject private var viewModel = EditorViewModel()

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(viewModel: viewModel)
                .environmentObject(settings)
                .frame(width: 260)

            Divider()

            VideoWorkspaceView(viewModel: viewModel)
                .frame(minWidth: 560)

            Divider()

            InspectorView(viewModel: viewModel)
                .frame(width: 420)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            viewModel.configure(settings: settings)
        }
        .onDrop(of: [UTType.movie.identifier, UTType.mpeg4Movie.identifier, UTType.quickTimeMovie.identifier, UTType.fileURL.identifier], isTargeted: nil) { providers in
            loadDroppedVideo(providers)
        }
        .overlay(alignment: .bottomLeading) {
            StatusBarView(message: viewModel.statusMessage)
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .background(
            KeyboardShortcutCatcher { event in
                handleKey(event)
            }
        )
    }

    private func loadDroppedVideo(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = item as? URL
            }
            guard let url else { return }
            Task { @MainActor in
                await viewModel.loadVideo(url: url)
            }
        }
        return true
    }

    private func handleKey(_ event: NSEvent) {
        switch event.keyCode {
        case 49:
            viewModel.togglePlayback()
        case 46:
            viewModel.addMarker()
        case 1:
            viewModel.captureCurrentScreenshot()
        case 123:
            viewModel.step(event.modifierFlags.contains(.shift) ? -1 : -5)
        case 124:
            viewModel.step(event.modifierFlags.contains(.shift) ? 1 : 5)
        case 51:
            viewModel.deleteSelectedMarker()
        default:
            break
        }
    }
}

private struct StatusBarView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
    }
}
