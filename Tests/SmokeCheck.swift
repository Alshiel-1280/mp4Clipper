import AVFoundation
import AppKit

// Standalone integration check: compiled with the production models/services/view models.
@main
struct SmokeCheck {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ClipBatcher-check-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        print("Artifacts: \(directory.path)")
        let source = directory.appendingPathComponent("fixture.mp4")
        let writer = try AVAssetWriter(outputURL: source, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 320, AVVideoHeightKey: 240
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: 320, kCVPixelBufferHeightKey as String: 240
        ])
        writer.add(input)
        guard writer.startWriting() else { throw writer.error! }
        writer.startSession(atSourceTime: .zero)
        for frame in 0..<120 {
            while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 1_000_000) }
            var buffer: CVPixelBuffer?
            precondition(CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer) == kCVReturnSuccess)
            CVPixelBufferLockBaseAddress(buffer!, [])
            memset(CVPixelBufferGetBaseAddress(buffer!)!, Int32(frame * 2), CVPixelBufferGetBytesPerRow(buffer!) * 240)
            CVPixelBufferUnlockBaseAddress(buffer!, [])
            precondition(adaptor.append(buffer!, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)))
        }
        input.markAsFinished()
        await writer.finishWriting()
        precondition(writer.status == .completed)
        let vm = EditorViewModel()
        await vm.loadVideo(url: source)
        precondition(vm.project != nil, vm.errorMessage ?? "Load failed")
        precondition(abs(vm.project!.metadata.duration - 4) < 0.05)
        vm.currentTime = 2
        vm.addMarker()
        precondition(vm.project!.markers.count == 1)
        var marker = vm.project!.markers[0]
        marker.clipStartOffsetSec = 1
        marker.clipEndOffsetSec = 1
        let range = vm.clipRange(for: marker)!
        precondition(range.start == 1 && range.end == 3)
        for (time, expectedStart, expectedEnd) in [(0.0, 0.0, 1.0), (4.0, 3.0, 4.0)] {
            marker.timestamp = time
            let edge = vm.clipRange(for: marker)!
            precondition(edge.start == expectedStart && edge.end == expectedEnd)
        }
        marker.clipStartOffsetSec = 0
        marker.clipEndOffsetSec = 0
        precondition(vm.clipRange(for: marker) == nil)
        let output = try FileNamingService.clipURL(sourceURL: source, index: 1, start: range.start, end: range.end, outputDirectory: directory)
        var finalProgress = 0.0
        try await ClipExportService.export(asset: vm.project!.asset, start: range.start, end: range.end, outputURL: output) { finalProgress = $0 }
        precondition(finalProgress == 1)
        let (exported, metadata) = try await VideoMetadataService.load(url: output)
        precondition(abs(metadata.duration - 2) < 0.05)
        precondition(metadata.resolution == "320 x 240")
        let image = try await ScreenshotExtractionService.extractImage(asset: exported, at: 0.5)
        for format in [ImageFormat.png, .jpeg] {
            let url = try FileNamingService.screenshotURL(sourceURL: source, index: 1, timestamp: 0.5, relativeOffset: nil, format: format, outputDirectory: directory)
            try ScreenshotExtractionService.write(image, to: url, format: format)
            precondition(NSImage(contentsOf: url) != nil)
        }
        let duplicate = try FileNamingService.clipURL(sourceURL: source, index: 1, start: 1, end: 3, outputDirectory: directory)
        precondition(duplicate != output)
        do {
            try await ClipExportService.export(asset: exported, start: 1, end: 1, outputURL: directory.appendingPathComponent("invalid.mp4")) { _ in }
            fatalError("Invalid range accepted")
        } catch { print("PASS: invalid export range rejected") }
        vm.deleteSelectedMarker()
        precondition(vm.project!.markers.isEmpty)
        print("PASS: load, marker create/delete, ranges, MP4 export (2s), decode, PNG/JPEG, unique filenames, progress")
    }
}
