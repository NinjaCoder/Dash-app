import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Colours from the redesign canvas. Contrast was chosen to pass 4.5:1 on the dark surfaces.
enum Theme {
    static let bg = Color(hex: 0x0D0F12)
    static let surface = Color(hex: 0x16191E)
    static let surface2 = Color(hex: 0x1E2228)
    static let line = Color(hex: 0x242931)
    static let lineStrong = Color(hex: 0x2A2F37)
    static let tabBar = Color(hex: 0x12151A)
    static let text = Color(hex: 0xF1F3F6)
    static let text2 = Color(hex: 0xA7AFBB)
    static let text3 = Color(hex: 0x8A93A1)
    static let teal = Color(hex: 0x3FD0BE)
    static let tealSoft = Color(hex: 0x12302C)
    static let onTeal = Color(hex: 0x07201C)
    static let amber = Color(hex: 0xF2B13E)
    static let amberSoft = Color(hex: 0x33291A)
    static let rec = Color(hex: 0xFF6B5E)
    static let overlay = Color(hex: 0x0D0F12, opacity: 0.82)
}

extension Font {
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension View {
    /// Rounded surface with a hairline border, used for every card.
    func card(_ radius: CGFloat = 16, fill: Color = Theme.surface, stroke: Color = Theme.line) -> some View {
        self
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }

    /// Small dark pill used on top of video.
    func overlayPill() -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.overlay, in: Capsule())
    }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
