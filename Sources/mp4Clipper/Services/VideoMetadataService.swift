import AVFoundation
import Foundation

enum VideoMetadataService {
    static func load(url: URL) async throws -> (AVURLAsset, VideoMetadata) {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let track = tracks.first

        var resolution = "不明"
        var displayAspectRatio = 16.0 / 9.0
        var frameRate: Double?

        if let track {
            let size = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformed = size.applying(transform)
            let displayWidth = abs(transformed.width)
            let displayHeight = abs(transformed.height)
            resolution = "\(Int(displayWidth)) x \(Int(displayHeight))"
            if displayWidth > 0, displayHeight > 0 {
                displayAspectRatio = Double(displayWidth / displayHeight)
            }
            let fps = try await track.load(.nominalFrameRate)
            frameRate = fps > 0 ? Double(fps) : nil
        }

        return (
            asset,
            VideoMetadata(
                filename: url.lastPathComponent,
                duration: duration.isFinite ? duration : 0,
                resolution: resolution,
                displayAspectRatio: displayAspectRatio,
                frameRate: frameRate
            )
        )
    }
}
