import SwiftUI

enum ClipType: String, CaseIterable, Identifiable, Hashable {
    case event, parking, normal, timelapse

    var id: String { rawValue }

    var label: String {
        switch self {
        case .event: return "Event"
        case .parking: return "Parking"
        case .normal: return "Normal"
        case .timelapse: return "Timelapse"
        }
    }

    var filterLabel: String {
        switch self {
        case .event: return "Events"
        default: return label
        }
    }

    var dot: Color {
        switch self {
        case .event: return Theme.amber
        case .parking: return Theme.teal
        case .normal: return Theme.text2
        case .timelapse: return Color(hex: 0xC9CED6)
        }
    }
}

struct Clip: Identifiable, Hashable {
    let id: UUID
    /// Day of month in October 2026 (sample data). A real camera service would use a Date.
    let day: Int
    let time: String
    let hour: Int
    let type: ClipType
    let title: String
    let sky: UInt32
    let speedKmh: Int
    let gForce: Double?
    let sizeMB: Double
    var saved: Bool
    var locked: Bool

    var durationLabel: String { type == .timelapse ? "0:30" : "1:00" }
    var durationSeconds: Double { type == .timelapse ? 30 : 60 }
    var cameras: String { type == .timelapse ? "Front · parking" : "Front + Rear" }
    var isNight: Bool { hour >= 20 || hour < 6 }

    var dayLabel: String {
        "\(DayInfo.weekday(for: day)) \(day) Oct"
    }

    var endTime: String {
        // Clips are 1 minute (timelapse 30 s); good enough for sample timestamps.
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return time }
        var total = parts[0] * 3600 + parts[1] * 60 + parts[2] + Int(durationSeconds)
        total %= 86_400
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }
}

struct DayInfo: Identifiable, Hashable {
    let day: Int
    let count: Int
    var id: Int { day }
    var weekday: String { DayInfo.weekday(for: day) }

    static func weekday(for day: Int) -> String {
        // 19 October 2026 is a Monday.
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = ((day - 19) % 7 + 7) % 7
        return names[index]
    }
}

struct DeviceStatus {
    var name: String
    var connected: Bool
    var cameras: String
    var sdUsedGB: Double
    var sdTotalGB: Double
    var firmwareUpdateAvailable: Bool
    var parkingArmed: Bool

    var sdFraction: Double { sdTotalGB > 0 ? sdUsedGB / sdTotalGB : 0 }
}

struct DownloadItem: Identifiable {
    enum State { case queued, downloading, retrying, done }

    let id = UUID()
    let clipID: UUID
    let name: String
    let type: ClipType
    let sky: UInt32
    let sizeMB: Double
    var progress: Double
    var state: State
    var retryIn: Int = 0

    var doneMB: Double { sizeMB * progress }
}
