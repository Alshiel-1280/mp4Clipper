import Foundation

enum FileNamingService {
    static func clipsDirectory(in outputDirectory: URL) throws -> URL {
        try ensureDirectory(outputDirectory.appendingPathComponent("Clips", isDirectory: true))
    }

    static func screenshotsDirectory(in outputDirectory: URL) throws -> URL {
        try ensureDirectory(outputDirectory.appendingPathComponent("Screenshots", isDirectory: true))
    }

    static func clipURL(sourceURL: URL, index: Int, start: Double, end: Double, outputDirectory: URL) throws -> URL {
        let directory = try clipsDirectory(in: outputDirectory)
        let base = sourceURL.deletingPathExtension().lastPathComponent
        let name = "\(base)_clip_\(String(format: "%03d", index))_\(TimeFormattingService.filenameTime(start))_to_\(TimeFormattingService.filenameTime(end)).mp4"
        return uniqueURL(directory.appendingPathComponent(name))
    }

    static func screenshotURL(
        sourceURL: URL,
        index: Int,
        timestamp: Double,
        relativeOffset: Double?,
        format: ImageFormat,
        outputDirectory: URL
    ) throws -> URL {
        let directory = try screenshotsDirectory(in: outputDirectory)
        let base = sourceURL.deletingPathExtension().lastPathComponent
        let offset = TimeFormattingService.signedOffset(relativeOffset)
            .replacingOccurrences(of: "+", with: "plus")
            .replacingOccurrences(of: "-", with: "minus")
            .replacingOccurrences(of: ".", with: "_")
        let name = "\(base)_shot_\(String(format: "%03d", index))_t\(TimeFormattingService.filenameTime(timestamp))_\(offset).\(format.fileExtension)"
        return uniqueURL(directory.appendingPathComponent(name))
    }

    static func uniqueURL(_ proposedURL: URL) -> URL {
        let manager = FileManager.default
        guard manager.fileExists(atPath: proposedURL.path) else { return proposedURL }

        let directory = proposedURL.deletingLastPathComponent()
        let base = proposedURL.deletingPathExtension().lastPathComponent
        let ext = proposedURL.pathExtension

        var counter = 2
        while true {
            let candidate = directory.appendingPathComponent("\(base)_\(counter).\(ext)")
            if !manager.fileExists(atPath: candidate.path) {
                return candidate
            }
            counter += 1
        }
    }

    @discardableResult
    private static func ensureDirectory(_ url: URL) throws -> URL {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
