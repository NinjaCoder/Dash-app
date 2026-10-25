import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                deviceCard
                recentEvents
                shortcuts
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
    }

    private var header: some View {
        HStack {
            ScreenTitle(title: "Home", subtitle: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            Spacer()
            IconButton(systemName: "bell", label: "Alerts", badge: !app.recentEvents.isEmpty) {
                app.galleryDay = app.recentEvents.first?.day ?? app.galleryDay
                app.tab = .gallery
            }
        }
        .padding(.horizontal, 20)
    }

    private var deviceCard: some View {
        VStack(spacing: 0) {
            Button {
                Haptics.tap()
                app.tab = .live
            } label: {
                RoadScene()
                    .frame(height: 156)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 6) {
                            Circle().fill(Theme.rec).frame(width: 7, height: 7)
                            Text("LIVE · REC").font(.system(size: 12, weight: .bold)).tracking(0.5)
                        }
                        .foregroundStyle(Theme.text)
                        .overlayPill()
                        .padding(12)
                    }
                    .overlay(alignment: .topTrailing) {
                        Text("Front").font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xC9CED6))
                            .overlayPill()
                            .padding(12)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Label("Open live view", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.onTeal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.teal, in: Capsule())
                            .padding(12)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open live view")

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.device.name).font(.system(size: 18, weight: .bold))
                        HStack(spacing: 6) {
                            Circle().fill(app.device.connected ? Theme.teal : Theme.text3).frame(width: 7, height: 7)
                            Text(app.device.connected ? "Connected over Wi-Fi · \(app.device.cameras)" : "Connecting…")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.text2)
                        }
                    }
                    Spacer()
                    Button {
                        app.tab = .settings
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 44, height: 44)
                            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Camera settings")
                }

                HStack(spacing: 8) {
                    statTile("SD card", value: "\(Int(app.device.sdUsedGB)) / \(Int(app.device.sdTotalGB)) GB") {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(hex: 0x2E343D))
                                Capsule().fill(Theme.teal).frame(width: geo.size.width * app.device.sdFraction)
                            }
                        }
                        .frame(height: 4)
                    }
                    statTile(
                        "Firmware",
                        value: app.device.firmwareUpdateAvailable ? "Update ready" : "Up to date",
                        valueColor: app.device.firmwareUpdateAvailable ? Theme.amber : Theme.text
                    ) { EmptyView() }
                    statTile("Parking", value: app.device.parkingArmed ? "Armed" : "Off") { EmptyView() }
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .card(24)
        .padding(.horizontal, 20)
    }

    private func statTile<Extra: View>(
        _ label: String,
        value: String,
        valueColor: Color = Theme.text,
        @ViewBuilder extra: () -> Extra
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text3)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            extra()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var recentEvents: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent events").font(.system(size: 18, weight: .bold))
                Spacer()
                Button("See all") { app.tab = .gallery }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.teal)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(app.recentEvents) { clip in
                        NavigationLink(value: clip) {
                            VStack(alignment: .leading, spacing: 8) {
                                ClipThumbnail(clip: clip, height: 88)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(clip.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.text)
                                    Text("\(clip.day == 25 ? "Today" : DayInfo.weekday(for: clip.day)) · \(String(clip.time.prefix(5)))")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.text3)
                                }
                            }
                            .frame(width: 156)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts").font(.system(size: 18, weight: .bold))
            HStack(spacing: 8) {
                shortcut("Find by date", "calendar") { app.tab = .gallery }
                shortcut("Save events", "arrow.down.to.line") {
                    let ids = app.clips.filter { $0.type == .event && !$0.saved }.map(\.id)
                    app.download(ids)
                }
                shortcut("Snapshot", "camera") {
                    Haptics.success()
                    app.show("Snapshot saved to your phone")
                }
                shortcut("SD health", "sdcard") { app.tab = .settings }
            }
        }
        .padding(.horizontal, 20)
    }

    private func shortcut(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.teal)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .padding(.horizontal, 4)
            .card(16)
        }
        .buttonStyle(.plain)
    }
}
