import Foundation

enum ImageFormat: String, CaseIterable, Identifiable {
    case png
    case jpeg

    var id: String { rawValue }
    var fileExtension: String { rawValue == "jpeg" ? "jpg" : "png" }
    var label: String { rawValue.uppercased() }
}
