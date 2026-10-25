import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Tab: Hashable { case home, gallery, live, saved, settings }

    @Published var tab: Tab = .home
    @Published var device = DeviceStatus(
        name: "My Dash Cam", connected: false, cameras: "Front + Rear",
        sdUsedGB: 0, sdTotalGB: 0, firmwareUpdateAvailable: false, parkingArmed: false
    )
    @Published var clips: [Clip] = []
    @Published var downloads: [DownloadItem] = []
    @Published var downloadsPaused = false
    @Published var toast: String?

    /// Day the Gallery opens on (24 October in the sample data).
    @Published var galleryDay = 24

    private let camera: CameraService
    private var timer: Timer?
    private var toastTask: Task<Void, Never>?

    init(camera: CameraService = MockCameraService()) {
        self.camera = camera
        Task { await load() }
        startTimer()
    }

    func load() async {
        do {
            device = try await camera.connect()
            clips = try await camera.fetchClips()
            seedSampleDownloads()
        } catch {
            show("Couldn't reach the camera. Check its Wi-Fi.")
        }
    }

    // MARK: - Clips

    var days: [DayInfo] {
        (19...25).map { day in DayInfo(day: day, count: clips.filter { $0.day == day }.count) }
    }

    func clips(on day: Int) -> [Clip] {
        clips.filter { $0.day == day }
    }

    var recentEvents: [Clip] {
        clips.filter { $0.type == .event || $0.type == .parking }.prefix(4).map { $0 }
    }

    var savedClips: [Clip] {
        clips.filter { $0.saved }
    }

    func clip(_ id: UUID) -> Clip? {
        clips.first { $0.id == id }
    }

    func toggleLock(_ id: UUID) {
        guard let i = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[i].locked.toggle()
        show(clips[i].locked ? "Clip locked. The camera won't overwrite it." : "Clip unlocked")
    }

    // MARK: - Downloads (simulated; a real build would use a background URLSession)

    var isDownloading: Bool {
        downloads.contains { $0.state != .done }
    }

    var activeDownloads: [DownloadItem] {
        downloads.filter { $0.state != .done }
    }

    var totalMB: Double { activeDownloads.reduce(0) { $0 + $1.sizeMB } }
    var doneMB: Double { activeDownloads.reduce(0) { $0 + $1.doneMB } }

    func download(_ ids: [UUID]) {
        var added = 0
        for id in ids {
            guard let found = clips.first(where: { $0.id == id }), !found.saved,
                  !downloads.contains(where: { $0.clipID == id && $0.state != .done }) else { continue }
            downloads.append(
                DownloadItem(
                    clipID: found.id,
                    name: "\(found.dayLabel) · \(String(found.time.prefix(5)))",
                    type: found.type,
                    sky: found.sky,
                    sizeMB: found.sizeMB,
                    progress: 0,
                    state: .queued
                )
            )
            added += 1
        }
        if added == 0 {
            show("Already saved to your phone")
        } else {
            downloadsPaused = false
            Haptics.success()
            show(added == 1 ? "Saving 1 clip in the background" : "Saving \(added) clips in the background")
        }
    }

    func togglePause() {
        downloadsPaused.toggle()
        Haptics.tap()
    }

    func clearFinished() {
        downloads.removeAll { $0.state == .done }
    }

    private func seedSampleDownloads() {
        let picks = clips.filter { !$0.saved && ($0.type == .event || $0.type == .parking) }.prefix(3)
        for (i, clip) in picks.enumerated() {
            downloads.append(
                DownloadItem(
                    clipID: clip.id,
                    name: "\(clip.dayLabel) · \(String(clip.time.prefix(5)))",
                    type: clip.type,
                    sky: clip.sky,
                    sizeMB: clip.sizeMB,
                    progress: i == 0 ? 0.62 : (i == 2 ? 0.15 : 0),
                    state: i == 0 ? .downloading : (i == 2 ? .retrying : .queued),
                    retryIn: i == 2 ? 5 : 0
                )
            )
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private var tickCount = 0

    private func tick() {
        guard !downloadsPaused else { return }
        tickCount += 1

        // Count down any "Wi-Fi dropped" retries once per second.
        if tickCount % 2 == 0 {
            for i in downloads.indices where downloads[i].state == .retrying {
                downloads[i].retryIn -= 1
                if downloads[i].retryIn <= 0 { downloads[i].state = .queued }
            }
        }

        // One transfer at a time, like a camera over Wi-Fi.
        let active = downloads.firstIndex { $0.state == .downloading }
            ?? downloads.firstIndex { $0.state == .queued }
        guard let i = active else { return }

        downloads[i].state = .downloading
        let mbPerTick = 4.2 // about 8.4 MB/s
        downloads[i].progress = min(1, downloads[i].progress + mbPerTick / downloads[i].sizeMB)

        if downloads[i].progress >= 1 {
            downloads[i].state = .done
            if let c = clips.firstIndex(where: { $0.id == downloads[i].clipID }) {
                clips[c].saved = true
            }
            if !isDownloading {
                Haptics.success()
                show("All clips saved to your phone")
            }
        }
    }

    // MARK: - Toast

    func show(_ message: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.3)) { toast = message }
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
        }
    }
}
