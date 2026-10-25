import SwiftUI

struct GalleryView: View {
    enum Source: Hashable { case camera, phone, cloud }

    @EnvironmentObject private var app: AppState
    @State private var source: Source = .camera
    @State private var filter: ClipType?
    @State private var selecting = false
    @State private var selection: Set<UUID> = []
    @State private var showCalendar = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    // MARK: Data

    private var dayClips: [Clip] {
        let all = app.clips(on: app.galleryDay)
        switch source {
        case .camera: return all
        case .phone: return all.filter { $0.saved }
        case .cloud: return []
        }
    }

    private var shownClips: [Clip] {
        guard let filter else { return dayClips }
        return dayClips.filter { $0.type == filter }
    }

    private var dayLabel: String {
        "\(DayInfo.weekday(for: app.galleryDay)) \(app.galleryDay) Oct"
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Segmented(
                    options: [(Source.camera, "On camera"), (Source.phone, "On phone"), (Source.cloud, "Cloud")],
                    selection: $source,
                    selectedFill: Theme.lineStrong,
                    selectedText: Theme.text
                )
                .padding(.horizontal, 20)
                dayStrip
                activityBars
                filterChips
                summary
                if shownClips.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .padding(.top, 8)
            .padding(.bottom, selecting ? 96 : 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Clip.self) { clip in
            ClipPlayerView(clipID: clip.id)
        }
        .overlay(alignment: .bottom) {
            if selecting { selectionBar }
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheet(day: $app.galleryDay, days: app.days)
                .presentationDetents([.medium])
                .presentationBackground(Theme.surface)
        }
        .onChange(of: app.galleryDay) { _, _ in selection.removeAll() }
    }

    private var header: some View {
        HStack {
            ScreenTitle(title: "Gallery")
            Spacer()
            IconButton(systemName: "calendar", label: "Pick a date") { showCalendar = true }
            Button {
                Haptics.tap()
                withAnimation(.snappy) {
                    selecting.toggle()
                    selection.removeAll()
                }
            } label: {
                Text(selecting ? "Done" : "Select")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(selecting ? Theme.teal : Theme.text)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .card(14)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var dayStrip: some View {
        VStack(spacing: 10) {
            HStack {
                Text("October 2026").font(.system(size: 15, weight: .bold))
                Spacer()
                Button {
                    shiftDay(-1)
                } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 32)
                }
                .accessibilityLabel("Previous day")
                Button {
                    shiftDay(1)
                } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 32)
                }
                .accessibilityLabel("Next day")
            }
            .foregroundStyle(Color(hex: 0xC9CED6))
            .font(.system(size: 15, weight: .bold))

            HStack(spacing: 6) {
                ForEach(app.days) { info in
                    dayPill(info)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func dayPill(_ info: DayInfo) -> some View {
        let selected = info.day == app.galleryDay
        let empty = info.count == 0
        return Button {
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { app.galleryDay = info.day }
        } label: {
            VStack(spacing: 3) {
                Text(info.day == 25 ? "Today" : info.weekday)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selected ? Theme.onTeal : Theme.text3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(info.day)")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(selected ? Theme.onTeal : (empty ? Theme.text3 : Theme.text))
                Circle()
                    .fill(empty ? Color.clear : (selected ? Theme.onTeal : Theme.teal))
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(selected ? Theme.teal : Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        selected ? Theme.teal : (empty ? Color(hex: 0x3A404A) : Theme.line),
                        style: StrokeStyle(lineWidth: 1, dash: empty && !selected ? [4, 3] : [])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(info.weekday) \(info.day) October, \(empty ? "no recordings" : "\(info.count) clips")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func shiftDay(_ delta: Int) {
        let next = min(25, max(19, app.galleryDay + delta))
        withAnimation(.snappy(duration: 0.2)) { app.galleryDay = next }
    }

    private var activityBars: some View {
        let profile: [Double] = [1, 0, 2, 0, 0, 0, 0, 2, 6, 3, 1, 1, 2, 4, 2, 1, 2, 4, 7, 5, 2, 1, 2, 3]
        let clips = app.clips(on: app.galleryDay)
        let eventHours = Set(clips.filter { $0.type == .event }.map(\.hour))
        let hasClips = !clips.isEmpty

        return VStack(spacing: 8) {
            HStack {
                Text("Activity by hour").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.text2)
                Spacer()
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.amber).frame(width: 8, height: 8)
                    Text("Event").font(.system(size: 12)).foregroundStyle(Theme.text2)
                }
            }
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<24, id: \.self) { hour in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(!hasClips ? Theme.lineStrong : (eventHours.contains(hour) ? Theme.amber : Color(hex: 0x2E7F75)))
                        .frame(height: hasClips ? 4 + profile[hour] * 4 : 3)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 32, alignment: .bottom)
            .accessibilityHidden(true)
            HStack {
                ForEach(["00", "06", "12", "18", "23"], id: \.self) { label in
                    Text(label)
                    if label != "23" { Spacer() }
                }
            }
            .font(.mono(11, .medium))
            .foregroundStyle(Theme.text3)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(nil, "All", dayClips.count)
                ForEach(ClipType.allCases) { type in
                    chip(type, type.filterLabel, dayClips.filter { $0.type == type }.count)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ type: ClipType?, _ title: String, _ count: Int) -> some View {
        let on = filter == type
        return Button {
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { filter = type }
        } label: {
            HStack(spacing: 6) {
                Text(title).font(.system(size: 13, weight: .bold))
                Text("\(count)").font(.system(size: 13, weight: .semibold)).opacity(0.75)
            }
            .foregroundStyle(on ? Theme.bg : Color(hex: 0xC9CED6))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(on ? Theme.text : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(on ? Theme.text : Theme.lineStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var summary: some View {
        let all = app.clips(on: app.galleryDay)
        return HStack(alignment: .firstTextBaseline) {
            Text(dayLabel).font(.system(size: 17, weight: .bold))
            Spacer()
            Text("\(all.count) clips · \(all.filter { $0.saved }.count) saved")
                .font(.system(size: 13))
                .foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 20)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(shownClips) { clip in
                if selecting {
                    Button {
                        Haptics.tap()
                        if selection.contains(clip.id) { selection.remove(clip.id) } else { selection.insert(clip.id) }
                    } label: {
                        clipCard(clip, selected: selection.contains(clip.id))
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(value: clip) {
                        clipCard(clip, selected: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func clipCard(_ clip: Clip, selected: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ClipThumbnail(clip: clip, height: 96, selected: selected)
            VStack(alignment: .leading, spacing: 2) {
                Text(clip.time).font(.mono(14)).foregroundStyle(Theme.text)
                Text(clip.cameras).font(.system(size: 12)).foregroundStyle(Theme.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(clip.type.label) clip at \(clip.time)\(clip.saved ? ", saved" : "")")
    }

    private var emptyState: some View {
        let noneThatDay = app.clips(on: app.galleryDay).isEmpty
        let title: String
        let text: String
        switch (source, noneThatDay) {
        case (.cloud, _):
            title = "No cloud clips"
            text = "Clips you upload to the cloud will appear here."
        case (_, true):
            title = "No recordings on \(dayLabel)"
            text = "The camera was off that day, or parked without parking mode."
        case (.phone, false):
            title = "Nothing saved from \(dayLabel)"
            text = "Switch to On camera and tap Select to save clips."
        default:
            title = "No \(filter?.label.lowercased() ?? "") clips on \(dayLabel)"
            text = "Try another type or another day."
        }

        return VStack(spacing: 10) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 22))
                .foregroundStyle(Theme.text3)
                .frame(width: 48, height: 48)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(title).font(.system(size: 16, weight: .bold)).multilineTextAlignment(.center)
            Text(text).font(.system(size: 13)).foregroundStyle(Theme.text2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(hex: 0x2E343D), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Text(selection.isEmpty ? "Tap clips to select" : "\(selection.count) selected")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                app.download(Array(selection))
                withAnimation(.snappy) {
                    selecting = false
                    selection.removeAll()
                }
            } label: {
                Label("Save to phone", systemImage: "arrow.down.to.line")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.onTeal)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Theme.teal, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selection.isEmpty)
            .opacity(selection.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .card(20, fill: Theme.surface2, stroke: Theme.lineStrong)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Real calendar for jumping to a day.
private struct CalendarSheet: View {
    @Binding var day: Int
    let days: [DayInfo]
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    private func makeDate(_ d: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d)) ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Jump to a day").font(.system(size: 18, weight: .bold))
                Spacer()
                Button("Done") { dismiss() }.font(.system(size: 16, weight: .semibold))
            }
            DatePicker(
                "Day",
                selection: $date,
                in: makeDate(19)...makeDate(25),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            Text("Sample data covers 19–25 October.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.text3)
        }
        .padding(20)
        .onAppear { date = makeDate(day) }
        .onChange(of: date) { _, newValue in
            let picked = calendar.component(.day, from: newValue)
            guard picked != day else { return }
            day = picked
            dismiss()
        }
    }
}
