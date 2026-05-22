import AVFoundation
import Foundation

enum VideoMetadataService {
    static func load(url: URL) async throws -> (AVURLAsset, VideoMetadata) {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let track = tracks.first

        var resolution = "不明"
        var frameRate: Double?

        if let track {
            let size = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformed = size.applying(transform)
            resolution = "\(Int(abs(transformed.width))) x \(Int(abs(transformed.height)))"
            let fps = try await track.load(.nominalFrameRate)
            frameRate = fps > 0 ? Double(fps) : nil
        }

        return (
            asset,
            VideoMetadata(
                filename: url.lastPathComponent,
                duration: duration.isFinite ? duration : 0,
                resolution: resolution,
                frameRate: frameRate
            )
        )
    }
}
