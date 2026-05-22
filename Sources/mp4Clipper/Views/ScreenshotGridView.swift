import SwiftUI

struct ScreenshotGridView: View {
    @ObservedObject var viewModel: EditorViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 128), spacing: 10)
    ]

    var selectedCandidate: ScreenshotCandidate? {
        guard let id = viewModel.selectedScreenshotID else { return nil }
        return viewModel.project?.screenshotCandidates.first { $0.id == id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("スクショ候補")
                    .font(.headline)
                Spacer()
                Button("選択を保存") {
                    viewModel.saveSelectedScreenshots()
                }
                .disabled(viewModel.project?.screenshotCandidates.isEmpty ?? true)
            }

            if let selectedCandidate, let image = selectedCandidate.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 190)
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .black))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.project?.screenshotCandidates ?? []) { candidate in
                        ScreenshotTile(viewModel: viewModel, candidate: candidate)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ScreenshotTile: View {
    @ObservedObject var viewModel: EditorViewModel
    let candidate: ScreenshotCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .topLeading) {
                if let image = candidate.previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(.secondary.opacity(0.2))
                }
                Toggle("", isOn: Binding(
                    get: { candidate.isSelected },
                    set: { _ in viewModel.toggleScreenshotSelection(id: candidate.id) }
                ))
                .labelsHidden()
                .padding(4)
            }
            .frame(height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(viewModel.selectedScreenshotID == candidate.id ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectedScreenshotID = candidate.id
            }

            HStack {
                Text(TimeFormattingService.clock(candidate.timestamp))
                    .font(.caption.monospaced())
                Spacer()
                Button(role: .destructive) {
                    viewModel.deleteScreenshot(id: candidate.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            Text(TimeFormattingService.signedOffset(candidate.relativeOffsetSec))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
