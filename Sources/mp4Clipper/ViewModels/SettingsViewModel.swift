import AppKit
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultClipStartOffsetSec: Double {
        didSet { defaults.set(defaultClipStartOffsetSec, forKey: Keys.defaultClipStartOffsetSec) }
    }
    @Published var defaultClipEndOffsetSec: Double {
        didSet { defaults.set(defaultClipEndOffsetSec, forKey: Keys.defaultClipEndOffsetSec) }
    }
    @Published var screenshotOffsetsText: String {
        didSet { defaults.set(screenshotOffsetsText, forKey: Keys.screenshotOffsetsText) }
    }
    @Published var imageFormat: ImageFormat {
        didSet { defaults.set(imageFormat.rawValue, forKey: Keys.imageFormat) }
    }
    @Published var outputDirectory: URL? {
        didSet { defaults.set(outputDirectory?.path, forKey: Keys.outputDirectoryPath) }
    }

    private let defaults = UserDefaults.standard

    var screenshotOffsets: [Double] {
        screenshotOffsetsText
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .sorted()
    }

    init() {
        let start = defaults.object(forKey: Keys.defaultClipStartOffsetSec) as? Double
        let end = defaults.object(forKey: Keys.defaultClipEndOffsetSec) as? Double
        let offsets = defaults.string(forKey: Keys.screenshotOffsetsText)
        let format = defaults.string(forKey: Keys.imageFormat).flatMap(ImageFormat.init(rawValue:))
        let outputPath = defaults.string(forKey: Keys.outputDirectoryPath)

        defaultClipStartOffsetSec = start ?? 5
        defaultClipEndOffsetSec = end ?? 20
        screenshotOffsetsText = offsets ?? "-1.0, -0.5, 0, 0.5, 1.0"
        imageFormat = format ?? .png
        outputDirectory = outputPath.map(URL.init(fileURLWithPath:))
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "出力先を選択"
        if panel.runModal() == .OK {
            outputDirectory = panel.url
        }
    }

    private enum Keys {
        static let defaultClipStartOffsetSec = "defaultClipStartOffsetSec"
        static let defaultClipEndOffsetSec = "defaultClipEndOffsetSec"
        static let screenshotOffsetsText = "screenshotOffsetsText"
        static let imageFormat = "imageFormat"
        static let outputDirectoryPath = "outputDirectoryPath"
    }
}
