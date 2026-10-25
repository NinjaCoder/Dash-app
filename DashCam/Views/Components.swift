import SwiftUI

/// Drawn placeholder for camera footage: sky, skyline, road and lane markings.
/// Replaced by real thumbnails / video once a camera service supplies them.
struct RoadScene: View {
    var sky: Color = Color(hex: 0x2A3A52)
    var night = false

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let horizon = h * 0.49

            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x1A2230)))
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon)), with: .color(sky))

            let buildings: [(CGFloat, CGFloat, CGFloat)] = [
                (0.17, 0.075, 0.20), (0.29, 0.05, 0.31), (0.69, 0.125, 0.24), (0.84, 0.0625, 0.38)
            ]
            for b in buildings {
                let rect = CGRect(x: b.0 * w, y: horizon - b.2 * h, width: b.1 * w, height: b.2 * h)
                ctx.fill(Path(rect), with: .color(Color(hex: night ? 0x111823 : 0x1E2A3B)))
            }

            var road = Path()
            road.move(to: CGPoint(x: 0, y: h))
            road.addLine(to: CGPoint(x: w * 0.425, y: horizon))
            road.addLine(to: CGPoint(x: w * 0.575, y: horizon))
            road.addLine(to: CGPoint(x: w, y: h))
            road.closeSubpath()
            ctx.fill(road, with: .color(Color(hex: 0x12161C)))

            var lane = Path()
            lane.move(to: CGPoint(x: w / 2, y: horizon + 2))
            lane.addLine(to: CGPoint(x: w / 2, y: h))
            ctx.stroke(
                lane,
                with: .color(Color(hex: night ? 0x8B93A0 : 0xC9CED6)),
                style: StrokeStyle(lineWidth: max(1, w / 130), dash: [max(3, w / 40), max(4, w / 32)])
            )

            if night {
                let r = max(2, w / 55)
                for x in [0.45, 0.55] {
                    let c = CGPoint(x: w * x, y: horizon + h * 0.13)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                        with: .color(Color(hex: 0xF2D27A))
                    )
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct TypeChip: View {
    let type: ClipType
    var text: String?

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(type.dot).frame(width: 6, height: 6)
            Text(text ?? type.label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Theme.overlay, in: Capsule())
    }
}

/// Thumbnail with type chip, duration and optional "saved" tick.
struct ClipThumbnail: View {
    let clip: Clip
    var height: CGFloat = 96
    var selected: Bool? = nil

    var body: some View {
        RoadScene(sky: Color(hex: clip.sky), night: clip.isNight)
            .frame(height: height)
            .overlay(alignment: .topLeading) {
                TypeChip(type: clip.type).padding(8)
            }
            .overlay(alignment: .topTrailing) {
                if let selected {
                    ZStack {
                        Circle().fill(selected ? Theme.teal : Theme.overlay)
                        Circle().stroke(selected ? Theme.teal : Theme.text, lineWidth: 1.5)
                        if selected {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Theme.onTeal)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .padding(8)
                } else if clip.saved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.onTeal)
                        .frame(width: 22, height: 22)
                        .background(Theme.teal, in: Circle())
                        .padding(8)
                        .accessibilityLabel("Saved to phone")
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Text(clip.durationLabel)
                    .font(.mono(11, .medium))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 6))
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ScreenTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let subtitle {
                Text(subtitle).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.text3)
            }
            Text(title)
                .font(.system(size: 30, weight: .heavy))
                .tracking(-0.5)
                .foregroundStyle(Theme.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(Theme.text3)
            .padding(.leading, 4)
    }
}

/// Square icon button with a border, 44 pt minimum.
struct IconButton: View {
    let systemName: String
    let label: String
    var badge = false
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .card(14)
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle().fill(Theme.amber)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                            .offset(x: -9, y: 9)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Three-way segmented control matching the design (Front / Rear / Split etc.).
struct Segmented<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var selectedFill: Color = Theme.teal
    var selectedText: Color = Theme.onTeal

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { item in
                let option = item.element
                let on = option.0 == selection
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.2)) { selection = option.0 }
                } label: {
                    Text(option.1)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(on ? selectedText : Theme.text2)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(on ? selectedFill : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .card(14)
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.teal)
            Text(message).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface2, in: Capsule())
        .overlay(Capsule().stroke(Theme.lineStrong, lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        .padding(.horizontal, 20)
    }
}
