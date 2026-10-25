import Foundation

/// Everything the app needs from a dash cam. The UI only talks to this protocol,
/// so a real camera connection can replace `MockCameraService` without touching any screen.
///
/// To connect a real 70mai A510 later:
/// 1. Join the camera's Wi-Fi from iOS Settings.
/// 2. Implement this protocol in an `A510CameraService` using the camera's HTTP endpoints
///    (not published by 70mai; they have to be worked out from the camera).
/// 3. Pass it into `AppState(camera:)` in DashCamApp.swift.
protocol CameraService {
    func connect() async throws -> DeviceStatus
    func fetchClips() async throws -> [Clip]
}

/// Sample data that matches the redesign canvas (week of 19–25 October 2026).
struct MockCameraService: CameraService {
    func connect() async throws -> DeviceStatus {
        DeviceStatus(
            name: "My Dash Cam",
            connected: true,
            cameras: "Front + Rear",
            sdUsedGB: 41,
            sdTotalGB: 128,
            firmwareUpdateAvailable: true,
            parkingArmed: true
        )
    }

    func fetchClips() async throws -> [Clip] {
        struct Template {
            let time: String
            let hour: Int
            let type: ClipType
            let title: String
            let sky: UInt32
            let speed: Int
            let g: Double?
        }

        let templates: [Template] = [
            Template(time: "23:02:45", hour: 23, type: .parking, title: "Parking bump", sky: 0x141B27, speed: 0, g: 0.9),
            Template(time: "18:42:10", hour: 18, type: .event, title: "Hard braking", sky: 0x3A4A62, speed: 38, g: 1.6),
            Template(time: "18:41:10", hour: 18, type: .normal, title: "Drive", sky: 0x3A4A62, speed: 44, g: nil),
            Template(time: "18:40:10", hour: 18, type: .normal, title: "Drive", sky: 0x3A4A62, speed: 51, g: nil),
            Template(time: "13:05:22", hour: 13, type: .normal, title: "Drive", sky: 0x4A6080, speed: 36, g: nil),
            Template(time: "08:14:02", hour: 8, type: .event, title: "Sudden swerve", sky: 0x50688A, speed: 29, g: 1.3),
            Template(time: "08:13:02", hour: 8, type: .normal, title: "Drive", sky: 0x50688A, speed: 33, g: nil),
            Template(time: "02:10:00", hour: 2, type: .timelapse, title: "Parked overnight", sky: 0x10151E, speed: 0, g: nil)
        ]

        // Clips per day: Mon 19 … Sun 25. Wednesday has none, to show the empty state.
        let counts: [Int: Int] = [19: 8, 20: 6, 21: 0, 22: 8, 23: 7, 24: 8, 25: 3]

        var clips: [Clip] = []
        for day in (19...25).reversed() {
            let n = counts[day] ?? 0
            for (index, t) in templates.prefix(n).enumerated() {
                clips.append(
                    Clip(
                        id: UUID(),
                        day: day,
                        time: t.time,
                        hour: t.hour,
                        type: t.type,
                        title: t.title,
                        sky: t.sky,
                        speedKmh: t.speed,
                        gForce: t.g,
                        sizeMB: t.type == .timelapse ? 45 : 90,
                        saved: day == 24 && (index == 0 || index == 1),
                        locked: t.type == .event
                    )
                )
            }
        }
        return clips
    }
}
