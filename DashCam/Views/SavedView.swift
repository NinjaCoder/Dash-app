import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var app: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if app.isDownloading {
                    transferCard
                    queue
                    recordingNote
                } else {
                    idleCard
                }
                onPhone
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Clip.self) { clip in
            ClipPlayerView(clipID: clip.id)
        }
        .animation(.snappy, value: app.isDownloading)
    }

    private var header: some View {
        HStack {
            ScreenTitle(title: "Saved")
            Spacer()
            let gb = Double(app.savedClips.count) * 0.09
            Text(String(format: "%.1f GB on phone", gb))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0xC9CED6))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .card(999)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Transfers

    private var transferCard: some View {
        let count = app.activeDownloads.count
        let fraction = app.totalMB > 0 ? app.doneMB / app.totalMB : 0
        let secondsLeft = Int((app.totalMB - app.doneMB) / 8.4)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: app.downloadsPaused ? "pause.fill" : "arrow.down.to.line")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Theme.teal)
                    .frame(width: 44, height: 44)
                    .background(Theme.tealSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.downloadsPaused ? "Paused · \(count) \(count == 1 ? "clip" : "clips")" : "Saving \(count) \(count == 1 ? "clip" : "clips")")
                        .font(.system(size: 17, weight: .heavy))
                    Text(String(format: "%.0f of %.0f MB", app.doneMB, app.totalMB) + (app.downloadsPaused ? "" : " · about \(max(1, secondsLeft)) s left"))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.text2)
                        .monospacedDigit()
                }
            }

            ProgressView(value: fraction)
                .tint(app.downloadsPaused ? Color(hex: 0x5A626E) : Theme.teal)
                .accessibilityLabel("Overall progress")

            HStack(spacing: 8) {
                promise("Keeps going if you leave the app")
                promise("Resumes after Wi-Fi drops")
            }

            Button {
                app.togglePause()
            } label: {
                Text(app.downloadsPaused ? "Resume all" : "Pause all")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.lineStrong, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .card(20, stroke: Color(hex: 0x2B4A46))
        .padding(.horizontal, 20)
    }

    private func promise(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy)).foregroundStyle(Theme.teal)
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: 0xC9CED6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.surface2, in: Capsule())
    }

    private var queue: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("In progress").font(.system(size: 18, weight: .bold)).padding(.bottom, 6)
            ForEach(app.activeDownloads) { item in
                row(item)
            }
        }
        .padding(.horizontal, 20)
    }

    private func row(_ item: DownloadItem) -> some View {
        let status: String
        var statusColor = Theme.text2
        if app.downloadsPaused {
            status = "Paused"
        } else {
            switch item.state {
            case .downloading:
                status = String(format: "8.4 MB/s · %.0f of %.0f MB", item.doneMB, item.sizeMB)
            case .queued:
                status = "Queued"
            case .retrying:
                status = "Wi-Fi dropped · retrying in \(item.retryIn) s"
                statusColor = Theme.amber
            case .done:
                status = "Saved"
            }
        }

        return HStack(spacing: 12) {
            RoadScene(sky: Color(hex: item.sky), night: item.type == .parking)
                .frame(width: 72, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name).font(.system(size: 14, weight: .bold))
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(item.type.dot).frame(width: 6, height: 6)
                        Text(item.type.label).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: 0xC9CED6))
                    }
                }
                ProgressView(value: item.progress)
                    .tint(app.downloadsPaused ? Color(hex: 0x5A626E) : Theme.teal)
                Text(status).font(.system(size: 12)).foregroundStyle(statusColor).monospacedDigit()
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var recordingNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield").foregroundStyle(Theme.teal)
            Text("Your camera keeps recording while clips are saved.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xC9CED6))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .card(14)
        .padding(.horizontal, 20)
    }

    private var idleCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(Theme.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing downloading").font(.system(size: 15, weight: .bold))
                Text("Choose clips in Gallery, then tap Save to phone.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text2)
            }
            Spacer(minLength: 0)
            Button("Gallery") { app.tab = .gallery }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.teal)
        }
        .padding(16)
        .card(18)
        .padding(.horizontal, 20)
    }

    // MARK: On this phone

    private var onPhone: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("On this phone").font(.system(size: 18, weight: .bold))
                Spacer()
                Text("This week · \(app.savedClips.count) clips")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text2)
            }

            if app.savedClips.isEmpty {
                Text("Saved clips will show up here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text3)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(app.savedClips) { clip in
                        NavigationLink(value: clip) {
                            VStack(alignment: .leading, spacing: 6) {
                                RoadScene(sky: Color(hex: clip.sky), night: clip.isNight)
                                    .frame(height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(alignment: .topLeading) {
                                        Circle().fill(clip.type.dot)
                                            .frame(width: 8, height: 8)
                                            .overlay(Circle().stroke(Theme.bg, lineWidth: 1.5))
                                            .padding(6)
                                    }
                                Text("\(DayInfo.weekday(for: clip.day)) · \(String(clip.time.prefix(5)))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.text)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(clip.type.label) clip, \(clip.dayLabel) at \(clip.time)")
                    }
                }
            }

            Label("Clips go to their own album, so limited photo access is enough.", systemImage: "lock")
                .font(.system(size: 12))
                .foregroundStyle(Theme.text2)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
    }
}
