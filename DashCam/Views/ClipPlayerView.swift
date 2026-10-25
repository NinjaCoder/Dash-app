import Combine
import SwiftUI

struct ClipPlayerView: View {
    @EnvironmentObject private var app: AppState
    @State private var currentID: UUID
    @State private var playing = false
    @State private var position: Double = 24 // seconds
    @State private var speed: Double = 1
    @State private var rear = false

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(clipID: UUID) {
        _currentID = State(initialValue: clipID)
    }

    private var clip: Clip? { app.clip(currentID) }

    private var sameDay: [Clip] {
        guard let clip else { return [] }
        return app.clips(on: clip.day)
    }

    var body: some View {
        Group {
            if let clip {
                content(clip)
            } else {
                Text("Clip not found").foregroundStyle(Theme.text2)
            }
        }
        .background(Theme.bg)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let clip {
                    VStack(spacing: 1) {
                        Text(clip.dayLabel).font(.system(size: 16, weight: .heavy))
                        Text("\(clip.time) – \(clip.endTime)").font(.mono(11, .medium)).foregroundStyle(Theme.text2)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let clip {
                    ShareLink(
                        item: "Dash cam clip \(clip.dayLabel) \(clip.time) (\(clip.type.label))",
                        subject: Text("Dash cam clip")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onReceive(ticker) { _ in
            guard playing, let clip else { return }
            position += 0.1 * speed
            if position >= clip.durationSeconds {
                position = clip.durationSeconds
                playing = false
            }
        }
    }

    private func content(_ clip: Clip) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                video(clip)
                scrubber(clip)
                transport(clip)
                details(clip)
                routeCard
                actions(clip)
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Video

    private func video(_ clip: Clip) -> some View {
        RoadScene(sky: Color(hex: rear ? 0x141B27 : clip.sky), night: rear || clip.isNight)
            .frame(height: 220)
            .clipped()
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    Circle().fill(clip.type.dot).frame(width: 7, height: 7)
                    Text(clip.type == .normal ? "Normal recording" : "\(clip.type.label) · \(clip.title)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Theme.text)
                .overlayPill()
                .padding(12)
            }
            .overlay(alignment: .bottomLeading) {
                Text("\(clip.speedKmh) km/h").font(.mono(12)).foregroundStyle(Theme.text).overlayPill().padding(12)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Haptics.tap()
                    rear.toggle()
                } label: {
                    Label(rear ? "Rear" : "Front", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Theme.overlay, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch camera, showing \(rear ? "rear" : "front")")
                .padding(12)
            }
            .overlay {
                if !playing {
                    Button {
                        togglePlay(clip)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.text)
                            .frame(width: 64, height: 64)
                            .background(Theme.overlay, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { if playing { togglePlay(clip) } }
            .gesture(
                DragGesture(minimumDistance: 40).onEnded { value in
                    if value.translation.width < -60 { step(1) }
                    if value.translation.width > 60 { step(-1) }
                }
            )
    }

    // MARK: Scrubber

    private func scrubber(_ clip: Clip) -> some View {
        let duration = clip.durationSeconds
        let impact: Double? = clip.gForce == nil ? nil : duration * 0.62

        return VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let x = w * CGFloat(position / duration)
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.lineStrong).frame(height: 6)
                    Capsule().fill(Theme.teal).frame(width: max(6, x), height: 6)
                    if let impact {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.amber)
                            .frame(width: 4, height: 14)
                            .offset(x: w * CGFloat(impact / duration) - 2)
                    }
                    Circle().fill(Theme.text).frame(width: 18, height: 18).offset(x: x - 9)
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { value in
                        let fraction = min(1, max(0, value.location.x / w))
                        position = Double(fraction) * duration
                    }
                )
            }
            .frame(height: 24)
            .accessibilityElement()
            .accessibilityLabel("Playback position")
            .accessibilityValue("\(timeString(position)) of \(timeString(duration))")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: position = min(duration, position + 5)
                case .decrement: position = max(0, position - 5)
                @unknown default: break
                }
            }

            HStack {
                Text(timeString(position))
                Spacer()
                if let impact {
                    Button("Impact \(timeString(impact))") { position = max(0, impact - 3) }
                        .foregroundStyle(Theme.amber)
                    Spacer()
                }
                Text(timeString(duration))
            }
            .font(.mono(12, .medium))
            .foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Transport

    private func transport(_ clip: Clip) -> some View {
        HStack {
            transportButton("backward.end.fill", "Previous clip") { step(-1) }
            Button("−10s") { position = max(0, position - 10) }
                .font(.mono(13))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 48)
                .accessibilityLabel("Back 10 seconds")
            Button {
                togglePlay(clip)
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 56, height: 56)
                    .background(Theme.text, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playing ? "Pause" : "Play")
            .frame(maxWidth: .infinity)
            Button(speed == 1 ? "1×" : (speed == 2 ? "2×" : "0.5×")) {
                Haptics.tap()
                speed = speed == 1 ? 2 : (speed == 2 ? 0.5 : 1)
            }
            .font(.mono(13))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 48)
            .accessibilityLabel("Playback speed")
            transportButton("forward.end.fill", "Next clip") { step(1) }
        }
        .padding(.horizontal, 20)
    }

    private func transportButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Details

    private func details(_ clip: Clip) -> some View {
        HStack(spacing: 8) {
            tile("Speed", "\(clip.speedKmh) km/h", Theme.text)
            tile("Impact", clip.gForce.map { String(format: "%.1f g", $0) } ?? "None", clip.gForce == nil ? Theme.text : Theme.amber)
            tile("Cameras", clip.cameras, Theme.text)
        }
        .padding(.horizontal, 20)
    }

    private func tile(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text3)
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card(14)
        .accessibilityElement(children: .combine)
    }

    private var routeCard: some View {
        Button {
            app.show("Maps opens here once GPS data comes from the camera")
        } label: {
            HStack(spacing: 14) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x1E2630)))
                    var grid = Path()
                    for y in [0.35, 0.73] {
                        grid.move(to: CGPoint(x: 0, y: size.height * y))
                        grid.addLine(to: CGPoint(x: size.width, y: size.height * y))
                    }
                    for x in [0.3, 0.7] {
                        grid.move(to: CGPoint(x: size.width * x, y: 0))
                        grid.addLine(to: CGPoint(x: size.width * x, y: size.height))
                    }
                    ctx.stroke(grid, with: .color(Color(hex: 0x2A3440)), lineWidth: 3)
                    var route = Path()
                    route.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.88))
                    route.addCurve(
                        to: CGPoint(x: size.width * 0.89, y: size.height * 0.12),
                        control1: CGPoint(x: size.width * 0.3, y: size.height * 0.4),
                        control2: CGPoint(x: size.width * 0.6, y: size.height * 0.5)
                    )
                    ctx.stroke(route, with: .color(Theme.teal), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    let p = CGPoint(x: size.width * 0.56, y: size.height * 0.42)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(Theme.amber))
                }
                .frame(width: 72, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Route and impact point").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.text)
                    Text("GPS saved with this clip").font(.system(size: 13)).foregroundStyle(Theme.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.text2)
            }
            .padding(10)
            .card(16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: Actions

    private func actions(_ clip: Clip) -> some View {
        HStack(spacing: 8) {
            Button {
                app.download([clip.id])
            } label: {
                Label(clip.saved ? "Saved" : "Save to phone", systemImage: clip.saved ? "checkmark" : "arrow.down.to.line")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Theme.onTeal)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.teal, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .opacity(clip.saved ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .disabled(clip.saved)

            square("scissors", "Trim", Theme.text) {
                app.show("Trimming needs the real video file from the camera")
            }
            square(clip.locked ? "lock.fill" : "lock.open", clip.locked ? "Unlock clip" : "Lock clip", Theme.amber) {
                app.toggleLock(clip.id)
            }
        }
        .padding(.horizontal, 20)
    }

    private func square(_ icon: String, _ label: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .card(16, stroke: Theme.lineStrong)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Helpers

    private func togglePlay(_ clip: Clip) {
        Haptics.tap()
        if !playing && position >= clip.durationSeconds { position = 0 }
        playing.toggle()
    }

    private func step(_ delta: Int) {
        guard let index = sameDay.firstIndex(where: { $0.id == currentID }) else { return }
        let next = index + delta
        guard sameDay.indices.contains(next) else {
            app.show(delta > 0 ? "That's the last clip of the day" : "That's the first clip of the day")
            return
        }
        withAnimation(.snappy) {
            currentID = sameDay[next].id
            position = 0
            playing = false
        }
    }

    private func timeString(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.down))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
