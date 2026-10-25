import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppState

    @AppStorage("recordAudio") private var recordAudio = true
    @AppStorage("parkingMode") private var parkingMode = true
    @AppStorage("syncTime") private var syncTime = true
    @AppStorage("backupBeforeUpdate") private var backupBeforeUpdate = true
    @AppStorage("videoQuality") private var videoQuality = "4K · 1080p rear"
    @AppStorage("clipLength") private var clipLength = "1 min"
    @AppStorage("sensitivity") private var sensitivity = "Medium"
    @AppStorage("units") private var units = "km/h"
    @AppStorage("language") private var language = "English"

    @State private var query = ""
    @State private var updating = false
    @State private var updateProgress = 0.0
    @State private var showWhatsNew = false

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private func show(_ title: String, _ keywords: String = "") -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return true }
        return title.lowercased().contains(q) || keywords.lowercased().contains(q)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenTitle(title: "Settings")
                    searchField
                }
                .padding(.horizontal, 20)

                if app.device.firmwareUpdateAvailable && show("Firmware update", "software version backup") {
                    firmwareCard
                }

                section("Recording", rows: [
                    opt(show("Video quality", "resolution 4k 1080p"), picker("Video quality", $videoQuality, ["4K · 1080p rear", "2K · 1080p rear", "1080p · 1080p rear"])),
                    opt(show("Clip length", "loop minutes"), picker("Clip length", $clipLength, ["1 min", "2 min", "3 min"])),
                    opt(show("Impact sensitivity", "g-sensor collision event"), picker("Impact sensitivity", $sensitivity, ["Low", "Medium", "High"])),
                    opt(show("Record audio", "microphone sound"), toggle("Record audio", nil, $recordAudio))
                ])

                section("Parking", rows: [
                    opt(show("Parking mode", "parked bump guard"), toggle("Parking mode", "Records bumps while the car is parked", $parkingMode))
                ])

                section("Camera", rows: [
                    opt(show("Set time from phone", "date clock timestamp"), toggle("Set time from phone", "Keeps clip timestamps correct", $syncTime)),
                    opt(show("Back up before updates", "firmware restore"), toggle("Back up before updates", "Restores your settings afterwards", $backupBeforeUpdate)),
                    opt(show("SD card", "storage format memory"), valueRow("SD card", "\(Int(app.device.sdUsedGB)) of \(Int(app.device.sdTotalGB)) GB") {
                        app.show("Formatting the SD card needs the real camera connection")
                    })
                ])

                section("App", rows: [
                    opt(show("Units", "speed km mph"), picker("Units", $units, ["km/h", "mph"])),
                    opt(show("Language", ""), picker("Language", $language, ["English", "हिन्दी", "मराठी"])),
                    opt(show("Help and support", "contact faq"), valueRow("Help and support", "") {
                        app.show("Help Center would open here")
                    })
                ])

                if !anythingVisible {
                    Text("No settings match “\(query)”.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }

                Text("Sample build · camera connection not active yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.text3)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(ticker) { _ in
            guard updating else { return }
            updateProgress += 0.01
            if updateProgress >= 1 {
                updating = false
                app.device.firmwareUpdateAvailable = false
                Haptics.success()
                app.show(backupBeforeUpdate ? "Camera updated. Your settings were restored." : "Camera updated")
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What's new").font(.system(size: 20, weight: .heavy))
                Text("Release notes come from the camera maker once the real camera is connected.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.text2)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .presentationDetents([.fraction(0.3)])
            .presentationBackground(Theme.surface)
        }
    }

    private var anythingVisible: Bool {
        let titles = [
            ("Firmware update", "software version backup"), ("Video quality", "resolution 4k 1080p"),
            ("Clip length", "loop minutes"), ("Impact sensitivity", "g-sensor collision event"),
            ("Record audio", "microphone sound"), ("Parking mode", "parked bump guard"),
            ("Set time from phone", "date clock timestamp"), ("Back up before updates", "firmware restore"),
            ("SD card", "storage format memory"), ("Units", "speed km mph"), ("Language", ""),
            ("Help and support", "contact faq")
        ]
        return titles.contains { show($0.0, $0.1) }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.text2)
            TextField("", text: $query, prompt: Text("Search settings, e.g. parking").foregroundColor(Theme.text3))
                .font(.system(size: 15))
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel("Search settings")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.text3)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .card(14)
    }

    private var firmwareCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Firmware update", systemImage: "cpu")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.amber)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.amberSoft, in: Capsule())
            Text(updating ? "Updating your camera…" : "A new camera update is ready")
                .font(.system(size: 18, weight: .heavy))
            if updating {
                ProgressView(value: updateProgress).tint(Theme.amber)
                Text(updateProgress < 0.15 && backupBeforeUpdate ? "Backing up your settings…" : "Keep the camera powered on. Recording resumes when it's done.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xC9CED6))
            } else {
                Text(backupBeforeUpdate
                     ? "Takes about 4 minutes. Your settings, date and time are backed up first and restored automatically."
                     : "Takes about 4 minutes. Backup is off, so settings may reset after the update.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xC9CED6))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button {
                        Haptics.tap()
                        updateProgress = 0
                        updating = true
                    } label: {
                        Text("Update now")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(Theme.onTeal)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Theme.teal, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    Button {
                        showWhatsNew = true
                    } label: {
                        Text("What's new")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(hex: 0x4A3C1F), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .card(20, fill: Color(hex: 0x1C1A15), stroke: Color(hex: 0x4A3C1F))
        .padding(.horizontal, 20)
    }

    // MARK: Rows

    private func opt<V: View>(_ visible: Bool, _ view: V) -> AnyView? {
        visible ? AnyView(view) : nil
    }

    @ViewBuilder
    private func section(_ title: String, rows: [AnyView?]) -> some View {
        let visible = rows.compactMap { $0 }
        if !visible.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: title)
                VStack(spacing: 0) {
                    ForEach(visible.indices, id: \.self) { i in
                        if i > 0 { Divider().overlay(Theme.line) }
                        visible[i]
                    }
                }
                .card(16)
            }
            .padding(.horizontal, 20)
        }
    }

    private func toggle(_ title: String, _ subtitle: String?, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.text2)
                }
            }
        }
        .tint(Theme.teal)
        .padding(.horizontal, 16)
        .frame(minHeight: subtitle == nil ? 52 : 60)
    }

    private func picker(_ title: String, _ value: Binding<String>, _ options: [String]) -> some View {
        Menu {
            Picker(title, selection: value) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
        } label: {
            HStack {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Text(value.wrappedValue).font(.system(size: 14)).foregroundStyle(Theme.text2)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.text2)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
    }

    private func valueRow(_ title: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.system(size: 14)).foregroundStyle(Theme.text2)
                }
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.text2)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
