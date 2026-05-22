import AppKit
import Foundation

struct ScreenshotCandidate: Identifiable, Equatable {
    let id: UUID
    let markerID: UUID?
    let timestamp: Double
    let relativeOffsetSec: Double?
    var previewImage: NSImage?
    var isSelected: Bool
    var outputURL: URL?

    init(
        id: UUID = UUID(),
        markerID: UUID?,
        timestamp: Double,
        relativeOffsetSec: Double?,
        previewImage: NSImage? = nil,
        isSelected: Bool = true,
        outputURL: URL? = nil
    ) {
        self.id = id
        self.markerID = markerID
        self.timestamp = timestamp
        self.relativeOffsetSec = relativeOffsetSec
        self.previewImage = previewImage
        self.isSelected = isSelected
        self.outputURL = outputURL
    }

    static func == (lhs: ScreenshotCandidate, rhs: ScreenshotCandidate) -> Bool {
        lhs.id == rhs.id &&
        lhs.markerID == rhs.markerID &&
        lhs.timestamp == rhs.timestamp &&
        lhs.relativeOffsetSec == rhs.relativeOffsetSec &&
        lhs.isSelected == rhs.isSelected &&
        lhs.outputURL == rhs.outputURL
    }
}
