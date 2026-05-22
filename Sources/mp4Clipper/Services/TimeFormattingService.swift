import Foundation

enum TimeFormattingService {
    static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00:00" }
        let clamped = max(0, seconds)
        let total = Int(clamped.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    static func filenameTime(_ seconds: Double) -> String {
        clock(seconds).replacingOccurrences(of: ":", with: "-")
    }

    static func signedOffset(_ seconds: Double?) -> String {
        guard let seconds else { return "current" }
        return seconds >= 0
            ? String(format: "+%.1fs", seconds)
            : String(format: "%.1fs", seconds)
    }
}
