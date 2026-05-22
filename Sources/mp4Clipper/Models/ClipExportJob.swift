import Foundation

struct ClipExportJob: Identifiable, Equatable {
    let id: UUID
    let markerID: UUID
    let startTime: Double
    let endTime: Double
    var status: ExportStatus
    var progress: Double
    var outputURL: URL?

    init(
        id: UUID = UUID(),
        markerID: UUID,
        startTime: Double,
        endTime: Double,
        status: ExportStatus = .pending,
        progress: Double = 0,
        outputURL: URL? = nil
    ) {
        self.id = id
        self.markerID = markerID
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.progress = progress
        self.outputURL = outputURL
    }
}
