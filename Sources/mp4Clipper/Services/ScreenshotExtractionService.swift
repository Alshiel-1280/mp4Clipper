import AVFoundation
import AppKit
import Foundation

enum ScreenshotExtractionService {
    static func extractImage(asset: AVAsset, at seconds: Double) async throws -> NSImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)

        let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        let image: CGImage
        if #available(macOS 13.0, *) {
            let generated = try await generator.image(at: time)
            image = generated.image
        } else {
            image = try generator.copyCGImage(at: time, actualTime: nil)
        }
        return NSImage(cgImage: image, size: .zero)
    }

    static func write(_ image: NSImage, to url: URL, format: ImageFormat) throws {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            throw LocalizedErrorMessage("画像データを作成できません")
        }

        let data: Data?
        switch format {
        case .png:
            data = bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
        }

        guard let data else {
            throw LocalizedErrorMessage("画像ファイルをエンコードできません")
        }
        try data.write(to: url, options: .atomic)
    }
}
