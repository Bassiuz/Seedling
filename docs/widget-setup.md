# The home-screen widget

Four cells wide, two high: today's appointments on the left, what is left to do
on the right, with a checkbox beside each task.

The Dart half is shared by both platforms (`lib/logic/widget_payload.dart`,
`lib/data/widget_publisher.dart`). Both native halves are in the repository and
build with the app; there is nothing to set up by hand.

## What the app sends

`WidgetPublisher` writes one JSON blob under `seedling_today`:

```json
{"dayKey":"2026-07-28",
 "events":[{"time":"09:30","title":"Sprint planning"}],
 "tasks":[{"id":"aBc123","title":"Write the release notes","tag":"Moxify"}],
 "moreEvents":0,"moreTasks":2}
```

Tasks carry their id because the widget can check them off and something has to
know which task that was. The shape is built by `buildWidgetPayload` and covered
by `test/logic/widget_payload_test.dart`, so changing it is safe to do
test-first.

## Checking one off

Tapping a checkbox does **not** write to Firestore. It wakes a Dart background
isolate, which appends the id to `seedling_pending` and redraws the widget
without that row, so the tap feels like it did something. The app drains that
queue on launch and on resume and does the real write.

This is deliberate. A background isolate opening Firestore's offline database
while the app holds it is what produced `LOCK: Resource temporarily unavailable`
earlier in this project, and a home screen is a bad place to rediscover it. The
cost is that a task ticked on the widget is not in the cloud until you next open
the app — visible only if you check off on the phone and then look at another
device before opening Seedling.

## Android

Nothing to do — it builds with the app.

- `android/app/src/main/kotlin/dev/bassiuz/seedling/SeedlingWidgetProvider.kt`
- `android/app/src/main/res/layout/seedling_widget.xml`
- registered in `AndroidManifest.xml`

Long-press the home screen → **Widgets** → Seedling.

`RemoteViews` cannot loop, so all four rows a side exist in the layout and the
provider hides the ones it does not need. That is cheaper than a collection
widget for a list that is never long.

## iPhone

Nothing to do either — the `SeedlingWidget` extension target is in the Xcode
project, embedded in the app, and signed with the App Group.

- `ios/SeedlingWidget/SeedlingWidget.swift` — SwiftUI, and an `AppIntent`
  behind each checkbox
- `ios/SeedlingWidget/Info.plist`, `SeedlingWidget.entitlements`
- `ios/Runner/Runner.entitlements` — the app's half of the same group

Long-press the home screen → **+** → Seedling → Today, and pick the medium
size.

The extension deliberately depends on nothing but WidgetKit, SwiftUI and
AppIntents. Its checkbox writes the two shared keys itself rather than waking
Flutter, which keeps CocoaPods out of the target — and a target with no pods is
one that can be added to the project from a script instead of by hand.

Two things about the build that are easy to undo by accident:

- The **Embed Foundation Extensions** phase must sit *before* **Thin Binary**
  in the Runner target. Flutter's thinning script re-signs the app bundle, so
  the extension has to already be inside it; after it, Xcode reports
  `Cycle inside Runner`.
- The widget target is **iOS 17**, because interactive widgets do not exist
  before it. The app itself stays on iOS 15.

### If it shows the wrong thing

- **"Sprint planning" and two invented tasks** — that is the placeholder. The
  App Group is missing or misspelled on one of the two targets, which is nearly
  always the cause.
- **Checkboxes do nothing** — the phone is below iOS 17, where a widget cannot
  act at all. It still renders, with the checkboxes drawn faint and inert.
- **Nothing updates** — the app publishes only when the day page is open on
  today. Open it once.
