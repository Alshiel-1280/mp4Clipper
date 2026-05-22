import AVKit
import SwiftUI

struct VideoWorkspaceView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .black))
                if viewModel.project == nil {
                    VStack(spacing: 10) {
                        Image(systemName: "film")
                            .font(.system(size: 42))
                        Text("動画ファイルをドラッグ&ドロップ、または左のボタンから読み込み")
                    }
                    .foregroundStyle(.secondary)
                } else {
                    VideoPlayer(player: viewModel.player)
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(spacing: 8) {
                HStack {
                    Text(TimeFormattingService.clock(viewModel.currentTime))
                        .font(.system(.body, design: .monospaced))
                    Slider(
                        value: Binding(
                            get: { viewModel.currentTime },
                            set: { viewModel.seek(to: $0) }
                        ),
                        in: 0...(max(viewModel.project?.metadata.duration ?? 1, 1))
                    )
                    Text(TimeFormattingService.clock(viewModel.project?.metadata.duration ?? 0))
                        .font(.system(.body, design: .monospaced))
                }

                HStack(spacing: 8) {
                    Button { viewModel.step(-5) } label: { Image(systemName: "gobackward.5") }
                    Button { viewModel.step(-1) } label: { Image(systemName: "gobackward") }
                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .frame(width: 28)
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    Button { viewModel.step(1) } label: { Image(systemName: "goforward") }
                    Button { viewModel.step(5) } label: { Image(systemName: "goforward.5") }

                    Divider()
                        .frame(height: 24)

                    Button("現在位置にマーカー追加") {
                        viewModel.addMarker()
                    }
                    .keyboardShortcut("m", modifiers: [])

                    Button("現在位置をスクショ") {
                        viewModel.captureCurrentScreenshot()
                    }
                    .keyboardShortcut("s", modifiers: [])

                    Button("現在位置を保存") {
                        viewModel.saveCurrentScreenshot()
                    }
                }
                .disabled(viewModel.project == nil)
            }
        }
        .padding(16)
    }
}
