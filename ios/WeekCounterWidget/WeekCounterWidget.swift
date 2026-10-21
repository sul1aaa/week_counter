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
        let title: String
        let subtitle: String
        let secondary: String?
    }
}

enum PayloadStore {
    static let groupId = "group.com.example.weekCounter"
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

    static var name: String { isRussian ? "Счётчик выходных" : "Week Counter" }
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

    static func message(_ text: String, at date: Date) -> CountdownEntry {
        CountdownEntry(
            date: date, title: L10n.name, subtitle: text, secondary: nil,
            days: 0, dayShort: "", timerEnd: nil
        )
    }

    static var preview: CountdownEntry {
        CountdownEntry(
            date: .now, title: "Weekend in", subtitle: "Fri 18:00 · 2 days off",
            secondary: nil, days: 2, dayShort: "d",
            timerEnd: .now.addingTimeInterval(3 * 3600 + 20 * 60)
        )
    }
}

struct Provider: TimelineProvider {
    private static let day: TimeInterval = 86_400

    func placeholder(in context: Context) -> CountdownEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let entry = Self.entries(from: PayloadStore.load(), now: .now, limit: 1).first
        completion(entry ?? .preview)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now = Date()
        let payload = PayloadStore.load()
        let entries = Self.entries(from: payload, now: now, limit: 150)
        if entries.isEmpty {
            let text = payload?.strings.empty ?? L10n.setUp
            completion(Timeline(entries: [.message(text, at: now)], policy: .after(now.addingTimeInterval(6 * 3600))))
        } else {
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }

    /// One entry each time the day count drops or the segment changes. In between, the
    /// timer counts down on its own, so the widget stays exact without reloads.
    static func entries(from payload: Payload?, now: Date, limit: Int) -> [CountdownEntry] {
        guard let payload else { return [] }
        var entries: [CountdownEntry] = []
        for segment in payload.segments where segment.end.date > now {
            let end = segment.end.date
            var time = max(now, segment.start.date)
            guard let target = segment.target?.date else {
                entries.append(CountdownEntry(
                    date: time, title: segment.title, subtitle: segment.subtitle,
                    secondary: segment.secondary, days: 0, dayShort: "", timerEnd: nil
                ))
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
                entries.append(CountdownEntry(
                    date: time, title: segment.title, subtitle: segment.subtitle,
                    secondary: segment.secondary, days: max(days, 0),
                    dayShort: payload.strings.dayShort, timerEnd: boundary
                ))
                if entries.count >= limit { return entries }
                time = boundary
            }
        }
        return entries
    }
}

// MARK: - View

struct WeekCounterWidgetEntryView: View {
    var entry: CountdownEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .lineLimit(1)
            if let end = entry.timerEnd, end > entry.date {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if entry.days > 0 {
                        Text("\(entry.days)\(entry.dayShort)")
                    }
                    Text(timerInterval: entry.date...end, countsDown: true)
                }
                .font(.system(size: family == .systemSmall ? 26 : 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            Text(entry.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if family != .systemSmall, let secondary = entry.secondary {
                Text(secondary)
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.indigo.opacity(0.22), Color.purple.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct WeekCounterWidget: Widget {
    /// Must match `HomeWidgetSync.iOSName` in Dart.
    let kind = "WeekCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeekCounterWidgetEntryView(entry: entry)
                .tint(.indigo)
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
