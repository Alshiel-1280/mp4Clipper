import SwiftUI

struct MarkerListView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("マーカー")
                    .font(.headline)
                Spacer()
                Button("選択を書き出し") {
                    viewModel.exportSelectedClips()
                }
                .disabled(viewModel.project?.markers.isEmpty ?? true)
            }

            List(selection: $viewModel.selectedMarkerID) {
                ForEach(viewModel.project?.markers ?? []) { marker in
                    MarkerRow(viewModel: viewModel, marker: marker)
                        .tag(marker.id)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct MarkerRow: View {
    @ObservedObject var viewModel: EditorViewModel
    let marker: Marker

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: markerBinding(\.isSelected))
                    .labelsHidden()
                Button(TimeFormattingService.clock(marker.timestamp)) {
                    viewModel.jumpToMarker(marker)
                }
                .font(.system(.body, design: .monospaced))
                Spacer()
                Button {
                    viewModel.generateScreenshots(for: marker)
                } label: {
                    Image(systemName: "photo.on.rectangle")
                }
                Button {
                    viewModel.exportClip(marker: marker)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    viewModel.deleteMarker(id: marker.id)
                } label: {
                    Image(systemName: "trash")
                }
            }

            TextField("メモ", text: markerBinding(\.memo))
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("前")
                TextField("", value: markerBinding(\.clipStartOffsetSec), format: .number.precision(.fractionLength(1)))
                    .frame(width: 54)
                Text("秒")
                Text("後")
                TextField("", value: markerBinding(\.clipEndOffsetSec), format: .number.precision(.fractionLength(1)))
                    .frame(width: 54)
                Text("秒")
                Spacer()
            }
            .font(.caption)

            if let range = viewModel.clipRange(for: marker) {
                Text("\(TimeFormattingService.clock(range.start)) - \(TimeFormattingService.clock(range.end))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            } else {
                Text("切り抜き範囲が不正です")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func markerBinding<Value>(_ keyPath: WritableKeyPath<Marker, Value>) -> Binding<Value> {
        Binding(
            get: {
                viewModel.project?.markers.first(where: { $0.id == marker.id })?[keyPath: keyPath] ?? marker[keyPath: keyPath]
            },
            set: { value in
                guard let index = viewModel.project?.markers.firstIndex(where: { $0.id == marker.id }) else { return }
                viewModel.project?.markers[index][keyPath: keyPath] = value
            }
        )
    }
}
