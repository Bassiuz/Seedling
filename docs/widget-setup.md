# The home-screen widget

Four cells wide, two high: today's appointments on the left, what is left to do
on the right, with a checkbox beside each task.

The Dart half is done, tested and shared by both platforms
(`lib/logic/widget_payload.dart`, `lib/data/widget_publisher.dart`). Android is
done too. iOS needs one manual step, below, because an Xcode *target* cannot be
created from a command line.

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

## iPhone — the five-minute manual bit

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension**. Name it exactly
   `SeedlingWidget`. Untick "Include Live Activity" and "Include Configuration
   App Intent". When asked, do **not** activate the scheme.
3. Delete the `SeedlingWidget.swift` Xcode generated and drag in
   `ios/SeedlingWidget/SeedlingWidget.swift` from this repo instead — untick
   "Copy items if needed", and add it to the `SeedlingWidget` target only.
4. Select the **Runner** target → Signing & Capabilities → **+ Capability** →
   **App Groups** → add `group.dev.bassiuz.seedling`.
5. Do the same for the **SeedlingWidget** target. Both must have the identical
   group, or the widget reads an empty container.
6. Add the `home_widget` package to the widget target: **File → Add Package
   Dependencies… → Add Local…** and pick
   `ios/.symlinks/plugins/home_widget/ios`. The checkbox intent needs it.
7. Set the widget target's deployment target to **iOS 17** — interactive
   widgets do not exist before it. The app itself stays on iOS 15; below 17 the
   widget still renders, with the checkboxes drawn faint and inert.

### If it shows the wrong thing

- **"Sprint planning" and two invented tasks** — that is the placeholder. The
  App Group is missing or misspelled on one of the two targets, which is nearly
  always the cause.
- **Checkboxes do nothing** — the widget target is below iOS 17, or step 6 was
  skipped.
- **Nothing updates** — the app publishes only when the day page is open on
  today. Open it once.
