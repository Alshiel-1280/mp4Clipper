import SwiftUI

struct InspectorView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        TabView {
            MarkerListView(viewModel: viewModel)
                .tabItem { Text("Markers") }

            ExportQueueView(viewModel: viewModel)
                .tabItem { Text("Clips") }

            ScreenshotGridView(viewModel: viewModel)
                .tabItem { Text("Shots") }
        }
        .padding(10)
    }
}
