import Foundation

enum ExportStatus: Equatable {
    case pending
    case exporting
    case completed
    case failed(String)

    var label: String {
        switch self {
        case .pending: "待機中"
        case .exporting: "書き出し中"
        case .completed: "完了"
        case .failed(let message): "失敗: \(message)"
        }
    }
}
