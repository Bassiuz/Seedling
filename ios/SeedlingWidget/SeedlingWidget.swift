// Seedling's home-screen widget.
//
// This file is not compiled by Flutter. Add it to a Widget Extension target in
// Xcode as described in docs/ios-widget-setup.md — an extension target cannot
// be created from the command line.

import SwiftUI
import WidgetKit

private let appGroupId = "group.dev.bassiuz.seedling"
private let dataKey = "seedling_today"

struct Today: Decodable {
    let dayKey: String
    let next: String?
    let tasks: [String]
    let remaining: Int

    static let placeholder = Today(
        dayKey: "", next: "09:00 Vet appointment",
        tasks: ["Edit Cozy Zone", "Make Shorts clip"], remaining: 2)

    /// Whatever the app last wrote, or the placeholder before it has run.
    static func load() -> Today {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let raw = defaults.string(forKey: dataKey),
            let data = raw.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(Today.self, from: data)
        else { return .placeholder }
        return decoded
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let today: Today
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), today: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), today: Today.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Refresh on the hour; the app also pushes an update when data changes.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [Entry(date: Date(), today: Today.load())],
                            policy: .after(next)))
    }
}

struct SeedlingWidgetView: View {
    var entry: Entry

    private let paper = Color(red: 0.976, green: 0.961, blue: 0.925)
    private let ink = Color.black
    private let muted = Color(white: 0.33)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let next = entry.today.next {
                Text(next)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundColor(ink)
                    .lineLimit(1)
            }
            ForEach(entry.today.tasks, id: \.self) { task in
                HStack(alignment: .top, spacing: 6) {
                    Circle().stroke(ink, lineWidth: 1.5).frame(width: 9, height: 9)
                        .padding(.top, 4)
                    Text(task).font(.caption).foregroundColor(ink).lineLimit(1)
                }
            }
            if entry.today.remaining > 0 {
                Text("+\(entry.today.remaining) more")
                    .font(.caption2).foregroundColor(muted)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(paper, for: .widget)
    }
}

@main
struct SeedlingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SeedlingWidget", provider: Provider()) { entry in
            SeedlingWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("The next thing with a time on it, and what is still to do.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
