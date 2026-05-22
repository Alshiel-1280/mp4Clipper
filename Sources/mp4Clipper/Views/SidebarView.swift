import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: EditorViewModel
    @EnvironmentObject private var settings: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("mp4Clipper")
                .font(.title2.bold())

            Button("動画を選択") {
                viewModel.openVideoPanel()
            }
            .buttonStyle(.borderedProminent)

            GroupBox("動画情報") {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow("ファイル", viewModel.project?.metadata.filename ?? "-")
                    infoRow("長さ", TimeFormattingService.clock(viewModel.project?.metadata.duration ?? 0))
                    infoRow("解像度", viewModel.project?.metadata.resolution ?? "-")
                    infoRow("FPS", viewModel.project?.metadata.frameRate.map { String(format: "%.2f", $0) } ?? "-")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("出力先") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(settings.outputDirectory?.path ?? "未設定")
                        .font(.caption)
                        .lineLimit(3)
                        .textSelection(.enabled)
                    Button("出力フォルダを選択") {
                        settings.chooseOutputDirectory()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("ショートカット") {
                VStack(alignment: .leading, spacing: 5) {
                    shortcut("Space", "再生 / 停止")
                    shortcut("M", "マーカー追加")
                    shortcut("S", "スクショ生成")
                    shortcut("← / →", "5秒移動")
                    shortcut("Shift + ← / →", "1秒移動")
                    shortcut("Delete", "選択マーカー削除")
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding(14)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }

    private func shortcut(_ key: String, _ action: String) -> some View {
        HStack {
            Text(key)
                .font(.caption.monospaced())
                .frame(width: 92, alignment: .leading)
            Text(action)
        }
    }
}
