import AVFoundation
import Foundation

enum ClipExportService {
    static func export(
        asset: AVAsset,
        start: Double,
        end: Double,
        outputURL: URL,
        progress: @escaping @MainActor (Double) -> Void
    ) async throws {
        guard start >= 0, end > start else {
            throw LocalizedErrorMessage("切り抜き範囲が不正です")
        }
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw LocalizedErrorMessage("AVAssetExportSession を作成できません")
        }

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            end: CMTime(seconds: end, preferredTimescale: 600)
        )
        session.shouldOptimizeForNetworkUse = true

        let monitor = Task {
            while !Task.isCancelled {
                await progress(Double(session.progress))
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
        }

        await session.export()
        monitor.cancel()
        await progress(Double(session.progress))

        switch session.status {
        case .completed:
            await progress(1)
        case .failed:
            throw session.error ?? LocalizedErrorMessage("動画書き出しに失敗しました")
        case .cancelled:
            throw LocalizedErrorMessage("動画書き出しがキャンセルされました")
        default:
            throw LocalizedErrorMessage("動画書き出しが完了しませんでした")
        }
    }
}
