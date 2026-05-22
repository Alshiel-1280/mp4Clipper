import AVFoundation
import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var project: VideoProject?
    @Published var player = AVPlayer()
    @Published var currentTime: Double = 0
    @Published var isPlaying = false
    @Published var selectedMarkerID: UUID?
    @Published var selectedScreenshotID: UUID?
    @Published var errorMessage: String?
    @Published var statusMessage = "動画を読み込んでください"

    private var timeObserver: Any?
    private var settings: SettingsViewModel?

    func configure(settings: SettingsViewModel) {
        self.settings = settings
        installTimeObserverIfNeeded()
    }

    func openVideoPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Task { await loadVideo(url: url) }
        }
    }

    func loadVideo(url: URL) async {
        do {
            let (asset, metadata) = try await VideoMetadataService.load(url: url)
            let item = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: item)
            project = VideoProject(sourceURL: url, asset: asset, playerItem: item, metadata: metadata)
            currentTime = 0
            selectedMarkerID = nil
            selectedScreenshotID = nil
            statusMessage = "\(metadata.filename) を読み込みました"
        } catch {
            showError("動画読み込み失敗: \(error.localizedDescription)")
        }
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(to seconds: Double) {
        let duration = project?.metadata.duration ?? 0
        let target = min(max(0, seconds), duration)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = target
    }

    func step(_ seconds: Double) {
        seek(to: currentTime + seconds)
    }

    func addMarker() {
        guard var project else {
            showError("先に動画を読み込んでください")
            return
        }
        let marker = Marker(
            timestamp: currentTime,
            clipStartOffsetSec: settings?.defaultClipStartOffsetSec ?? 5,
            clipEndOffsetSec: settings?.defaultClipEndOffsetSec ?? 20
        )
        project.markers.append(marker)
        project.markers.sort { $0.timestamp < $1.timestamp }
        self.project = project
        selectedMarkerID = marker.id
        statusMessage = "マーカーを追加: \(TimeFormattingService.clock(marker.timestamp))"
    }

    func deleteSelectedMarker() {
        guard let selectedMarkerID else { return }
        deleteMarker(id: selectedMarkerID)
    }

    func deleteMarker(id: UUID) {
        guard var project else { return }
        project.markers.removeAll { $0.id == id }
        project.clipExportJobs.removeAll { $0.markerID == id }
        project.screenshotCandidates.removeAll { $0.markerID == id }
        self.project = project
        if selectedMarkerID == id { selectedMarkerID = nil }
    }

    func jumpToMarker(_ marker: Marker) {
        selectedMarkerID = marker.id
        seek(to: marker.timestamp)
    }

    func bindingForMarker(_ marker: Marker) -> BindingProxy<Marker>? {
        guard let index = project?.markers.firstIndex(where: { $0.id == marker.id }) else { return nil }
        return BindingProxy(
            get: { [weak self] in self?.project?.markers[index] ?? marker },
            set: { [weak self] updated in self?.project?.markers[index] = updated }
        )
    }

    func clipRange(for marker: Marker) -> (start: Double, end: Double)? {
        guard let duration = project?.metadata.duration else { return nil }
        let start = max(0, marker.timestamp - marker.clipStartOffsetSec)
        let end = min(duration, marker.timestamp + marker.clipEndOffsetSec)
        guard start < end else { return nil }
        return (start, end)
    }

    func exportClip(marker: Marker) {
        Task { await exportClips(markers: [marker]) }
    }

    func exportSelectedClips() {
        guard let markers = project?.markers.filter(\.isSelected), !markers.isEmpty else {
            showError("書き出すマーカーを選択してください")
            return
        }
        Task { await exportClips(markers: markers) }
    }

    func captureCurrentScreenshot() {
        Task { await generateScreenshot(marker: nil, timestamp: currentTime, relativeOffset: nil) }
    }

    func generateScreenshots(for marker: Marker) {
        let offsets = settings?.screenshotOffsets ?? [-1, -0.5, 0, 0.5, 1]
        Task {
            for offset in offsets {
                guard let duration = project?.metadata.duration else { return }
                let timestamp = min(max(0, marker.timestamp + offset), duration)
                await generateScreenshot(marker: marker, timestamp: timestamp, relativeOffset: offset)
            }
        }
    }

    func toggleScreenshotSelection(id: UUID) {
        guard let index = project?.screenshotCandidates.firstIndex(where: { $0.id == id }) else { return }
        project?.screenshotCandidates[index].isSelected.toggle()
    }

    func deleteScreenshot(id: UUID) {
        project?.screenshotCandidates.removeAll { $0.id == id }
        if selectedScreenshotID == id { selectedScreenshotID = nil }
    }

    func saveSelectedScreenshots() {
        Task { await writeSelectedScreenshots() }
    }

    private func exportClips(markers: [Marker]) async {
        guard let outputDirectory = settings?.outputDirectory else {
            showError("出力フォルダを設定してください")
            return
        }
        guard let project else { return }

        for (offset, marker) in markers.enumerated() {
            guard let range = clipRange(for: marker) else {
                appendFailedJob(marker: marker, message: "切り抜き範囲が不正です")
                continue
            }

            var jobID: UUID?
            do {
                let outputURL = try FileNamingService.clipURL(
                    sourceURL: project.sourceURL,
                    index: offset + 1,
                    start: range.start,
                    end: range.end,
                    outputDirectory: outputDirectory
                )
                var job = ClipExportJob(markerID: marker.id, startTime: range.start, endTime: range.end, status: .exporting)
                self.project?.clipExportJobs.append(job)
                jobID = job.id

                try await ClipExportService.export(asset: project.asset, start: range.start, end: range.end, outputURL: outputURL) { [weak self] progress in
                    self?.updateJob(id: job.id, progress: progress)
                }

                job.status = .completed
                job.progress = 1
                job.outputURL = outputURL
                updateJob(job)
                statusMessage = "クリップを書き出しました: \(outputURL.lastPathComponent)"
            } catch {
                if let jobID {
                    updateJob(id: jobID, status: .failed(error.localizedDescription))
                }
                showError("クリップ書き出し失敗: \(error.localizedDescription)")
            }
        }
    }

    private func generateScreenshot(marker: Marker?, timestamp: Double, relativeOffset: Double?) async {
        guard let project else {
            showError("先に動画を読み込んでください")
            return
        }
        do {
            let image = try await ScreenshotExtractionService.extractImage(asset: project.asset, at: timestamp)
            let candidate = ScreenshotCandidate(
                markerID: marker?.id,
                timestamp: timestamp,
                relativeOffsetSec: relativeOffset,
                previewImage: image
            )
            self.project?.screenshotCandidates.append(candidate)
            selectedScreenshotID = candidate.id
            statusMessage = "スクショ候補を生成: \(TimeFormattingService.clock(timestamp))"
        } catch {
            showError("スクショ抽出失敗: \(error.localizedDescription)")
        }
    }

    private func writeSelectedScreenshots() async {
        guard let outputDirectory = settings?.outputDirectory else {
            showError("出力フォルダを設定してください")
            return
        }
        guard let sourceURL = project?.sourceURL else { return }
        let format = settings?.imageFormat ?? .png
        let selected = project?.screenshotCandidates.filter(\.isSelected) ?? []
        guard !selected.isEmpty else {
            showError("保存するスクショを選択してください")
            return
        }

        for (index, candidate) in selected.enumerated() {
            guard let image = candidate.previewImage else { continue }
            do {
                let url = try FileNamingService.screenshotURL(
                    sourceURL: sourceURL,
                    index: index + 1,
                    timestamp: candidate.timestamp,
                    relativeOffset: candidate.relativeOffsetSec,
                    format: format,
                    outputDirectory: outputDirectory
                )
                try ScreenshotExtractionService.write(image, to: url, format: format)
                if let candidateIndex = project?.screenshotCandidates.firstIndex(where: { $0.id == candidate.id }) {
                    project?.screenshotCandidates[candidateIndex].outputURL = url
                }
                statusMessage = "スクショを保存しました: \(url.lastPathComponent)"
            } catch {
                showError("スクショ保存失敗: \(error.localizedDescription)")
            }
        }
    }

    private func installTimeObserverIfNeeded() {
        guard timeObserver == nil else { return }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds.isFinite ? time.seconds : 0
            }
        }
    }

    private func appendFailedJob(marker: Marker, message: String) {
        guard let range = clipRange(for: marker) else { return }
        project?.clipExportJobs.append(
            ClipExportJob(markerID: marker.id, startTime: range.start, endTime: range.end, status: .failed(message))
        )
    }

    private func updateJob(_ job: ClipExportJob) {
        guard let index = project?.clipExportJobs.firstIndex(where: { $0.id == job.id }) else { return }
        project?.clipExportJobs[index] = job
    }

    private func updateJob(id: UUID, progress: Double) {
        guard let index = project?.clipExportJobs.firstIndex(where: { $0.id == id }) else { return }
        project?.clipExportJobs[index].progress = progress
    }

    private func updateJob(id: UUID, status: ExportStatus) {
        guard let index = project?.clipExportJobs.firstIndex(where: { $0.id == id }) else { return }
        project?.clipExportJobs[index].status = status
    }

    private func showError(_ message: String) {
        errorMessage = message
        statusMessage = message
    }
}

struct BindingProxy<Value> {
    let get: () -> Value
    let set: (Value) -> Void
}
