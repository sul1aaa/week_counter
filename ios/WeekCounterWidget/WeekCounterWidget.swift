import SwiftUI
import WidgetKit

// MARK: - Data written by the Flutter app (lib/domain/widget_payload.dart)

struct Payload: Decodable {
    let strings: Strings
    let segments: [Segment]

    struct Strings: Decodable {
        let dayShort: String
        let hourShort: String
        let minuteShort: String
        let empty: String?
    }

    /// Times are epoch milliseconds.
    struct Segment: Decodable {
        let start: Double
        let end: Double
        let mode: String
        let target: Double?
        /// Start of the run of workdays or of the time off; the orb fills from here to `target`.
        let from: Double?
        let title: String
        let subtitle: String
        let secondary: String?
    }
}

enum PayloadStore {
    static let groupId = "group.io.github.sul1aaa.orbity"
    static let key = "wc_payload_v1"

    static func load() -> Payload? {
        guard let json = UserDefaults(suiteName: groupId)?.string(forKey: key),
              let data = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }
}

/// The few strings shown before the app has sent any data.
enum L10n {
    private static var isRussian: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ru") ?? false
    }

    static var name: String { "Orbity" }
    static var description: String {
        isRussian ? "Обратный отсчёт до выходных и праздников" : "Countdown to your next weekend or holiday"
    }
    static var setUp: String {
        isRussian ? "Откройте приложение для настройки" : "Open the app to set up"
    }
}

private extension Double {
    var date: Date { Date(timeIntervalSince1970: self / 1000) }
}

// MARK: - Timeline

/// The orb's liquid colour, as in the app (lib/ui/kit/orb.dart).
enum OrbMode {
    /// Violet: the week is filling up.
    case work
    /// Lime: time off, draining back toward work.
    case weekend
    /// Grey: nothing to count.
    case paused
}

struct CountdownEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let secondary: String?
    /// Whole days left, shown next to the timer.
    let days: Int
    let dayShort: String
    /// When the timer reaches zero and the next entry takes over; nil hides it.
    let timerEnd: Date?
    /// Orb and bar fill, from 0 (empty) to 1 (full).
    let fill: Double
    let mode: OrbMode

    static func message(_ text: String, at date: Date) -> CountdownEntry {
        CountdownEntry(
            date: date, title: L10n.name, subtitle: text, secondary: nil,
            days: 0, dayShort: "", timerEnd: nil, fill: 0.5, mode: .paused
        )
    }

    static var preview: CountdownEntry {
        CountdownEntry(
            date: .now, title: "Weekend in", subtitle: "Fri 18:00 · 2 days off",
            secondary: nil, days: 2, dayShort: "d",
            timerEnd: .now.addingTimeInterval(3 * 3600 + 20 * 60),
            fill: 0.6, mode: .work
        )
    }
}

struct Provider: TimelineProvider {
    private static let day: TimeInterval = 86_400
    /// How often the orb and bar catch up. About 1% of a working week.
    private static let fillStep: TimeInterval = 3600

    func placeholder(in context: Context) -> CountdownEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let entry = Self.entries(from: PayloadStore.load(), now: .now, limit: 1).first
        completion(entry ?? .preview)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now = Date()
        let payload = PayloadStore.load()
        let entries = Self.entries(from: payload, now: now, limit: 240)
        if entries.isEmpty {
            let text = payload?.strings.empty ?? L10n.setUp
            completion(Timeline(entries: [.message(text, at: now)], policy: .after(now.addingTimeInterval(6 * 3600))))
        } else {
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }

    /// One entry each time the day count drops, the segment changes, or an hour passes
    /// for the orb. In between, the timer counts down on its own, so the widget stays
    /// exact without reloads.
    static func entries(from payload: Payload?, now: Date, limit: Int) -> [CountdownEntry] {
        guard let payload else { return [] }
        var entries: [CountdownEntry] = []
        for segment in payload.segments where segment.end.date > now {
            let end = segment.end.date
            let counting = segment.mode == "countdown"
            let target = segment.target?.date
            let from = segment.from?.date
            var time = max(now, segment.start.date)

            // Same as the app: how much of the run (or time off) is done; 0 if unknown.
            func fill(at time: Date) -> Double {
                var done = 0.0
                if let from, let target, target > from {
                    done = min(max(time.timeIntervalSince(from) / target.timeIntervalSince(from), 0), 1)
                }
                return counting ? done : 1 - done
            }

            func entry(at time: Date, days: Int, timerEnd: Date?) -> CountdownEntry {
                CountdownEntry(
                    date: time, title: segment.title, subtitle: segment.subtitle,
                    secondary: segment.secondary, days: max(days, 0),
                    dayShort: timerEnd == nil ? "" : payload.strings.dayShort,
                    timerEnd: timerEnd, fill: fill(at: time),
                    mode: counting ? .work : .weekend
                )
            }

            guard let target else {
                entries.append(entry(at: time, days: 0, timerEnd: nil))
                if entries.count >= limit { return entries }
                continue
            }
            while time < end {
                var days = Int((target.timeIntervalSince(time) / day).rounded(.down))
                var boundary = target.addingTimeInterval(-Double(days) * day)
                if boundary <= time {
                    days -= 1
                    boundary = boundary.addingTimeInterval(day)
                }
                entries.append(entry(at: time, days: days, timerEnd: boundary))
                if entries.count >= limit { return entries }
                time = min(boundary, time.addingTimeInterval(fillStep), end)
            }
        }
        return entries
    }
}

// MARK: - View

private extension Color {
    init(rgb: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Colors from the app's design: a near-black card in both themes.
enum Palette {
    static let background = Color(rgb: 0x111111)
    static let ink = Color(rgb: 0xF5F5F5)
    static let ink2 = Color(rgb: 0xA3A19C)
    static let violet = Color(rgb: 0xB9A0FF)
    static let barWork = Color(rgb: 0x8B5CF6)
    static let lime = Color(rgb: 0xC8F53C)
    static let barTrack = Color.white.opacity(0.12)
}

struct WeekCounterWidgetEntryView: View {
    var entry: CountdownEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemSmall {
                small
            } else {
                medium
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { Palette.background }
    }

    /// Like the in-app preview (lib/ui/widgets/widget_sheet.dart): the orb in the
    /// top corner, the timer at the bottom.
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                title.lineLimit(2)
                Spacer(minLength: 0)
                OrbView(size: 48, fill: entry.fill, mode: entry.mode)
            }
            Spacer(minLength: 4)
            timer(size: 28)
            subtitle
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 2)
            bar.padding(.top, 8)
        }
    }

    /// Text and bar on the left, a big orb on the right.
    private var medium: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                title.lineLimit(1)
                timer(size: 36)
                subtitle.lineLimit(2)
                if let secondary = entry.secondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                bar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            OrbView(size: 112, fill: entry.fill, mode: entry.mode)
        }
    }

    private var title: some View {
        Text(entry.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.ink2)
    }

    private var subtitle: some View {
        Text(entry.subtitle)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.ink2)
    }

    @ViewBuilder
    private func timer(size: CGFloat) -> some View {
        if let end = entry.timerEnd, end > entry.date {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if entry.days > 0 {
                    Text("\(entry.days)\(entry.dayShort)")
                }
                Text(timerInterval: entry.date...end, countsDown: true)
            }
            .font(.system(size: size, weight: .bold))
            .kerning(-1)
            .monospacedDigit()
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
    }

    private var bar: some View {
        FillBar(fill: entry.fill, color: entry.mode == .weekend ? Palette.lime : Palette.barWork)
    }
}

/// The app's progress line: 6 pt, rounded, on a faint track.
struct FillBar: View {
    let fill: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(color)
                .frame(width: geo.size.width * min(max(fill, 0), 1))
        }
        .frame(height: 6)
        .background(Palette.barTrack)
        .clipShape(Capsule())
    }
}

// MARK: - Orb

/// The app's glass orb, still and on dark glass, as the in-app widget preview draws it.
/// A port of `_OrbPainter` in lib/ui/kit/orb.dart with the waves at rest.
struct OrbView: View {
    let size: CGFloat
    let fill: Double
    let mode: OrbMode

    var body: some View {
        // The shadow reaches past the sphere; layout still takes only `size`.
        let margin = size * 0.4
        Canvas { context, _ in
            context.translateBy(x: margin, y: margin)
            OrbPainter(w: size, fill: min(max(fill, 0), 1), palette: OrbPalette(mode)).paint(in: context)
        }
        .frame(width: size + margin * 2, height: size + margin * 2)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Liquid colors: highlight at the surface, main and deep.
struct OrbPalette {
    let surface: Color
    let main: Color
    let deep: Color

    init(_ mode: OrbMode) {
        let rgb: (UInt32, UInt32, UInt32) = switch mode {
        case .work: (0xFF8AD8, 0x9B6BFF, 0x5B2FD6)
        case .weekend: (0x6FF2C7, 0xE4FF7A, 0x9EDB00)
        case .paused: (0xE6E3DD, 0xC9C6C0, 0x9C9890)
        }
        surface = Color(rgb: rgb.0)
        main = Color(rgb: rgb.1)
        deep = Color(rgb: rgb.2)
    }
}

private struct OrbPainter {
    /// Sphere diameter.
    let w: CGFloat
    let fill: Double
    let palette: OrbPalette

    private var r: CGFloat { w / 2 }
    private var rect: CGRect { CGRect(x: 0, y: 0, width: w, height: w) }

    /// A Flutter `Alignment` inside the sphere's box.
    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: r + x * r, y: r + y * r)
    }

    func paint(in context: GraphicsContext) {
        let k = w / 220
        let sphere = Path(ellipseIn: rect)
        let box = Path(rect)

        // Drop shadow, kept outside the sphere so it never shows through the glass.
        context.drawLayer { outside in
            var mask = Path(rect.insetBy(dx: -w, dy: -w))
            mask.addEllipse(in: rect)
            outside.clip(to: mask, style: FillStyle(eoFill: true))
            outside.drawLayer { glow in
                glow.addFilter(.blur(radius: 25 * k))
                let radius = r - 12 * k
                glow.fill(
                    Path(ellipseIn: CGRect(x: r - radius, y: r + 24 * k - radius, width: radius * 2, height: radius * 2)),
                    with: .color(.black.opacity(0.6))
                )
            }
        }

        context.drawLayer { glass in
            glass.clip(to: sphere)

            // Glass body.
            glass.fill(box, with: .linearGradient(
                Gradient(colors: [.white.opacity(0.14), Color(rgb: 0x7864C8, opacity: 0x14 / 255)]),
                startPoint: point(-0.34, -0.94), endPoint: point(0.34, 0.94)
            ))
            glass.fill(box, with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.28), location: 0),
                    .init(color: .white.opacity(0.04), location: 0.55),
                ]),
                center: point(-0.4, -0.6), startRadius: 0, endRadius: 1.06 * w
            ))

            // Liquid: a fainter back wave behind the front one.
            let top = (1 - fill) * w - 0.06 * w
            let bottom = top + 1.2 * w
            func liquid(_ svgTop: CGFloat, _ baseline: CGFloat) -> GraphicsContext.Shading {
                .linearGradient(
                    Gradient(stops: [
                        .init(color: palette.surface, location: 0),
                        .init(color: palette.main, location: 0.18),
                        .init(color: palette.deep, location: 1),
                    ]),
                    startPoint: CGPoint(x: 0, y: svgTop + (baseline - 10.5) * w / 200),
                    endPoint: CGPoint(x: 0, y: bottom)
                )
            }
            glass.drawLayer { back in
                back.opacity = 0.55
                back.fill(wave(top: top - 0.036 * w, baseline: 28, shift: 1, bottom: bottom),
                          with: liquid(top - 0.036 * w, 28))
            }
            glass.fill(wave(top: top, baseline: 22, shift: 0, bottom: bottom), with: liquid(top, 22))

            // Iridescent sheen, faded out toward the middle and the rim.
            glass.drawLayer { sheen in
                sheen.fill(box, with: .conicGradient(
                    Gradient(stops: [
                        .init(color: Color(rgb: 0xFF8AD8, opacity: 0x26 / 255), location: 0),
                        .init(color: Color(rgb: 0x7C4DF0, opacity: 0), location: 0.3),
                        .init(color: Color(rgb: 0x6FF2C7, opacity: 0x1A / 255), location: 0.5),
                        .init(color: Color(rgb: 0xC8F53C, opacity: 0), location: 0.72),
                        .init(color: Color(rgb: 0xFF8AD8, opacity: 0x26 / 255), location: 1),
                    ]),
                    center: point(0, 0), angle: .zero
                ))
                sheen.blendMode = .destinationIn
                sheen.fill(box, with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .black, location: 0.3),
                        .init(color: .black.opacity(0), location: 0.72),
                    ]),
                    center: point(0, 0), startRadius: 0, endRadius: w * sqrt(2) / 2
                ))
            }
        }

        // Rim.
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(.white.opacity(0.14)), lineWidth: 1)

        // Highlights: a soft oval up left and a small glint down right.
        var highlight = context
        highlight.translateBy(x: 0.35 * w, y: 0.21 * w)
        highlight.rotate(by: .degrees(-24))
        highlight.scaleBy(x: 0.17 * w, y: 0.11 * w)
        highlight.fill(
            Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.95), location: 0),
                    .init(color: .white.opacity(0), location: 0.99),
                ]),
                center: .zero, startRadius: 0, endRadius: 1
            )
        )
        var glint = context
        glint.translateBy(x: 0.78 * w, y: 0.825 * w)
        glint.rotate(by: .degrees(-30))
        glint.addFilter(.blur(radius: 0.01 * w))
        glint.fill(
            Path(ellipseIn: CGRect(x: -0.06 * w, y: -0.035 * w, width: 0.12 * w, height: 0.07 * w)),
            with: .color(.white.opacity(0.55))
        )
    }

    /// The prototype's SVG wave: an 800 × 240 box stretched over 2w × 1.2w, made of
    /// cubic curves that meet the baseline vertically. `baseline` is in SVG units;
    /// `shift` is how far along one period the wave has drifted.
    private func wave(top svgTop: CGFloat, baseline: CGFloat, shift: CGFloat, bottom: CGFloat) -> Path {
        let sx = w / 400, sy = w / 200
        let y = svgTop + baseline * sy
        let rise = 14 * sy
        let period = 200 * sx
        var x = -0.5 * w - shift * period
        var path = Path()
        path.move(to: CGPoint(x: x, y: bottom))
        path.addLine(to: CGPoint(x: x, y: y))
        for _ in 0..<5 {
            path.addCurve(
                to: CGPoint(x: x + 100 * sx, y: y),
                control1: CGPoint(x: x + 50 * sx, y: y - rise),
                control2: CGPoint(x: x + 100 * sx, y: y - rise)
            )
            path.addCurve(
                to: CGPoint(x: x + period, y: y),
                control1: CGPoint(x: x + 100 * sx, y: y + rise),
                control2: CGPoint(x: x + 150 * sx, y: y + rise)
            )
            x += period
        }
        path.addLine(to: CGPoint(x: x, y: bottom))
        path.closeSubpath()
        return path
    }
}

struct WeekCounterWidget: Widget {
    /// Must match `HomeWidgetSync.iOSName` in Dart.
    let kind = "WeekCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeekCounterWidgetEntryView(entry: entry)
                .tint(Palette.violet)
        }
        .configurationDisplayName(L10n.name)
        .description(L10n.description)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WeekCounterWidget()
} timeline: {
    CountdownEntry.preview
}

#Preview(as: .systemMedium) {
    WeekCounterWidget()
} timeline: {
    CountdownEntry.preview
}
