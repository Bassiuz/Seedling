import AppIntents
import SwiftUI
import WidgetKit
import home_widget

// Today at a glance: appointments on the left, what is left to do on the
// right. Four rows a side, which is what fits without the text shrinking to
// something you would not read across a room.

private let appGroup = "group.dev.bassiuz.seedling"
private let dataKey = "seedling_today"

// MARK: - What the app sends

struct SeedlingEvent: Decodable, Identifiable {
  let time: String
  let title: String
  var id: String { "\(time) \(title)" }
}

struct SeedlingTask: Decodable, Identifiable {
  let id: String
  let title: String
  let tag: String?
}

struct SeedlingDay: Decodable {
  let dayKey: String
  let events: [SeedlingEvent]
  let tasks: [SeedlingTask]
  let moreEvents: Int
  let moreTasks: Int

  /// Shown in the widget gallery, before the app has ever written anything.
  static let placeholder = SeedlingDay(
    dayKey: "",
    events: [SeedlingEvent(time: "09:30", title: "Sprint planning")],
    tasks: [
      SeedlingTask(id: "1", title: "Write the release notes", tag: "Moxify"),
      SeedlingTask(id: "2", title: "Water the greenhouse", tag: nil),
    ],
    moreEvents: 0,
    moreTasks: 0
  )

  static let empty = SeedlingDay(
    dayKey: "", events: [], tasks: [], moreEvents: 0, moreTasks: 0)

  static func read() -> SeedlingDay {
    guard
      let defaults = UserDefaults(suiteName: appGroup),
      let json = defaults.string(forKey: dataKey),
      let data = json.data(using: .utf8),
      let day = try? JSONDecoder().decode(SeedlingDay.self, from: data)
    else {
      // An empty container almost always means the App Group is missing or
      // misspelled on one of the two targets.
      return .empty
    }
    return day
  }
}

// MARK: - Ticking one off

/// Hands the tap to the Dart background isolate, which queues it. The widget
/// does not write to the database itself — see `lib/data/widget_publisher.dart`
/// for why.
@available(iOS 17.0, *)
struct ToggleTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Check off a task"

  @Parameter(title: "Task")
  var taskId: String

  init() {}
  init(taskId: String) { self.taskId = taskId }

  func perform() async throws -> some IntentResult {
    let escaped =
      taskId.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? taskId
    await HomeWidgetBackgroundWorker.run(
      url: URL(string: "seedling://toggle?id=\(escaped)"),
      appGroup: appGroup
    )
    return .result()
  }
}

// MARK: - The face of it

private let paper = Color(red: 0.98, green: 0.957, blue: 0.925)
private let ink = Color(red: 0.11, green: 0.098, blue: 0.09)
private let muted = Color(red: 0.42, green: 0.396, blue: 0.376)
private let faint = Color(red: 0.659, green: 0.635, blue: 0.604)

struct SeedlingWidgetView: View {
  let day: SeedlingDay

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      column(title: "Today") {
        if day.events.isEmpty {
          Text("Nothing scheduled").font(.caption).foregroundStyle(faint)
        }
        ForEach(day.events) { event in
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(event.time).font(.caption2).foregroundStyle(muted)
              .frame(width: 42, alignment: .leading)
            Text(event.title).font(.caption).foregroundStyle(ink).lineLimit(1)
          }
        }
        more(day.moreEvents)
      }

      Divider()

      column(title: "To do") {
        if day.tasks.isEmpty {
          Text("All done").font(.caption).foregroundStyle(faint)
        }
        ForEach(day.tasks) { task in
          HStack(spacing: 6) {
            checkbox(for: task)
            Text(task.title).font(.caption).foregroundStyle(ink).lineLimit(1)
          }
        }
        more(day.moreTasks)
      }
    }
    .padding(14)
  }

  @ViewBuilder
  private func checkbox(for task: SeedlingTask) -> some View {
    if #available(iOS 17.0, *) {
      Button(intent: ToggleTaskIntent(taskId: task.id)) {
        Circle().strokeBorder(ink, lineWidth: 2).frame(width: 16, height: 16)
      }
      .buttonStyle(.plain)
    } else {
      // Before iOS 17 a widget cannot act; tapping opens the app instead.
      Circle().strokeBorder(faint, lineWidth: 2).frame(width: 16, height: 16)
    }
  }

  @ViewBuilder
  private func more(_ count: Int) -> some View {
    if count > 0 {
      Text("+\(count) more").font(.caption2).foregroundStyle(faint)
    }
  }

  private func column<Content: View>(
    title: String, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title).font(.caption2.bold()).foregroundStyle(muted)
      content()
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Plumbing

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry {
    Entry(date: Date(), day: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(Entry(date: Date(), day: context.isPreview ? .placeholder : .read()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    // The app reloads this whenever anything changes, so one entry is enough;
    // the hourly refresh is only a safety net for a day that rolls over while
    // the app is closed.
    let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    completion(Timeline(entries: [Entry(date: Date(), day: .read())], policy: .after(next)))
  }

  struct Entry: TimelineEntry {
    let date: Date
    let day: SeedlingDay
  }
}

@main
struct SeedlingWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SeedlingWidget", provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        SeedlingWidgetView(day: entry.day)
          .containerBackground(paper, for: .widget)
      } else {
        ZStack { paper; SeedlingWidgetView(day: entry.day) }
      }
    }
    .configurationDisplayName("Today")
    .description("Your appointments and what is left to do.")
    .supportedFamilies([.systemMedium])
  }
}
