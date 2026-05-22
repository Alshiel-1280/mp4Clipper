import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsViewModel

    var body: some View {
        Form {
            Section("切り抜き") {
                HStack {
                    Text("デフォルト前秒")
                    TextField("", value: $settings.defaultClipStartOffsetSec, format: .number.precision(.fractionLength(1)))
                        .frame(width: 80)
                }
                HStack {
                    Text("デフォルト後秒")
                    TextField("", value: $settings.defaultClipEndOffsetSec, format: .number.precision(.fractionLength(1)))
                        .frame(width: 80)
                }
            }

            Section("スクリーンショット") {
                TextField("オフセット秒（カンマ区切り）", text: $settings.screenshotOffsetsText)
                Picker("画像形式", selection: $settings.imageFormat) {
                    ForEach(ImageFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("出力") {
                Text(settings.outputDirectory?.path ?? "未設定")
                    .font(.caption)
                    .textSelection(.enabled)
                Button("出力フォルダを選択") {
                    settings.chooseOutputDirectory()
                }
            }

            Section("ショートカット") {
                Text("Space: 再生/停止、M: マーカー追加、S: スクショ生成、←/→: 5秒移動、Shift+←/→: 1秒移動、Delete: 選択マーカー削除")
                    .font(.caption)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
