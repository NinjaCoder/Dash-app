import SwiftUI

struct LiveView: View {
    enum CameraMode: Hashable { case front, rear, split }

    @EnvironmentObject private var app: AppState
    @State private var mode: CameraMode = .front
    @State private var micOn = true
    @State private var fullScreen = false
    @State private var recBlink = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                preview
                    .frame(height: 220)
                    .clipped()
                Segmented(options: [(CameraMode.front, "Front"), (CameraMode.rear, "Rear"), (CameraMode.split, "Split")], selection: $mode)
                    .padding(.horizontal, 20)
                recordingNote
                controls
                quickSettings
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $fullScreen) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                preview.aspectRatio(16 / 9, contentMode: .fit).frame(maxHeight: .infinity)
                Button {
                    fullScreen = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 44, height: 44)
                        .background(Theme.overlay, in: Circle())
                }
                .accessibilityLabel("Close full screen")
                .padding(16)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { recBlink = false }
        }
    }

    private var header: some View {
        HStack {
            Button {
                app.tab = .home
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to Home")
            .padding(.leading, -10)

            Text("Live view").font(.system(size: 22, weight: .heavy))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Label("Strong signal", systemImage: "wifi")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0xC9CED6))
                .labelStyle(SignalLabelStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .card(999)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            Color(hex: 0x07090B)
            switch mode {
            case .front:
                RoadScene(sky: Color(hex: 0x2A3A52))
                    .overlay(alignment: .bottomTrailing) { pip(night: true) }
            case .rear:
                RoadScene(sky: Color(hex: 0x141B27), night: true)
                    .overlay(alignment: .bottomTrailing) { pip(night: false) }
            case .split:
                VStack(spacing: 2) {
                    RoadScene(sky: Color(hex: 0x2A3A52))
                    RoadScene(sky: Color(hex: 0x141B27), night: true)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 6) {
                Circle().fill(Theme.rec).frame(width: 7, height: 7).opacity(recBlink ? 1 : 0.25)
                Text("REC").font(.system(size: 12, weight: .bold)).tracking(0.5)
            }
            .foregroundStyle(Theme.text)
            .overlayPill()
            .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits)))
                    .font(.mono(12))
                    .foregroundStyle(Theme.text)
                    .overlayPill()
            }
            .padding(12)
        }
        .overlay(alignment: .bottomLeading) {
            Text("42 km/h").font(.mono(12)).foregroundStyle(Theme.text).overlayPill().padding(12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live camera preview, recording")
    }

    private func pip(night: Bool) -> some View {
        RoadScene(sky: Color(hex: night ? 0x141B27 : 0x2A3A52), night: night)
            .frame(width: 104, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.text, lineWidth: 2))
            .padding(12)
            .onTapGesture {
                withAnimation(.snappy) { mode = (mode == .front) ? .rear : .front }
            }
    }

    private var recordingNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.teal)
                .frame(width: 36, height: 36)
                .background(Theme.tealSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Recording continues while you watch").font(.system(size: 14, weight: .bold))
                Text("Loop and event recording stay on in the background.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .card(16)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            control("Snapshot", "camera", primary: false) {
                Haptics.success()
                app.show("Snapshot saved to your phone")
            }
            control("Save clip", "lock.fill", primary: true) {
                if let latest = app.clips.first(where: { !$0.saved }) {
                    app.download([latest.id])
                }
            }
            control(micOn ? "Mic on" : "Mic off", micOn ? "mic" : "mic.slash", primary: false) {
                micOn.toggle()
                app.show(micOn ? "Audio recording on" : "Audio recording off")
            }
            control("Full screen", "arrow.up.left.and.arrow.down.right", primary: false) {
                fullScreen = true
            }
        }
        .padding(.horizontal, 20)
    }

    private func control(_ title: String, _ icon: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(primary ? Theme.onTeal : Theme.text)
                    .frame(width: 60, height: 60)
                    .background(primary ? Theme.teal : Theme.surface2, in: Circle())
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("QUICK SETTINGS")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.text3)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)
            quickRow("Video quality", "4K front · 1080p rear")
            Divider().overlay(Theme.line)
            quickRow("Audio recording", micOn ? "On" : "Off")
        }
        .card(16)
        .padding(.horizontal, 20)
    }

    private func quickRow(_ title: String, _ value: String) -> some View {
        Button {
            app.tab = .settings
        } label: {
            HStack {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Text(value).font(.system(size: 14)).foregroundStyle(Theme.text2)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.text2)
            }
            .frame(minHeight: 52)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Teal icon, grey text.
private struct SignalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(Theme.teal)
            configuration.title
        }
    }
}
