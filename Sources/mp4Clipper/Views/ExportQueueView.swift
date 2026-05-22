import SwiftUI

struct ExportQueueView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("切り抜き候補")
                    .font(.headline)
                Spacer()
                Button("選択マーカーを書き出し") {
                    viewModel.exportSelectedClips()
                }
            }

            List {
                Section("候補") {
                    ForEach(viewModel.project?.markers ?? []) { marker in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(TimeFormattingService.clock(marker.timestamp))
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Button("書き出し") {
                                    viewModel.exportClip(marker: marker)
                                }
                                .buttonStyle(.borderless)
                            }

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
                        .padding(.vertical, 5)
                    }
                }

                Section("書き出し履歴") {
                    ForEach(viewModel.project?.clipExportJobs ?? []) { job in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(TimeFormattingService.clock(job.startTime)) - \(TimeFormattingService.clock(job.endTime))")
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Text(job.status.label)
                                    .font(.caption)
                                    .foregroundStyle(color(for: job.status))
                            }
                            ProgressView(value: job.progress)
                            if let outputURL = job.outputURL {
                                Text(outputURL.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }

    private func color(for status: ExportStatus) -> Color {
        switch status {
        case .completed: .green
        case .failed: .red
        case .exporting: .blue
        case .pending: .secondary
        }
    }
}
