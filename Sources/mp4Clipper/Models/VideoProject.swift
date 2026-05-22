import AVFoundation
import Foundation

struct VideoProject {
    var sourceURL: URL
    var asset: AVURLAsset
    var playerItem: AVPlayerItem
    var metadata: VideoMetadata
    var markers: [Marker] = []
    var screenshotCandidates: [ScreenshotCandidate] = []
    var clipExportJobs: [ClipExportJob] = []
}
