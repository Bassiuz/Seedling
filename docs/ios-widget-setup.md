# Adding the iPhone widget

The Dart half is done and tested. The widget itself is an Xcode *target*, which
cannot be created from the command line — this is the five-minute manual bit.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension**. Name it exactly
   `SeedlingWidget`. Untick "Include Live Activity" and "Include Configuration
   App Intent". When asked, do **not** activate the scheme.
3. Delete the `SeedlingWidget.swift` Xcode generated, and drag in
   `ios/SeedlingWidget/SeedlingWidget.swift` from this repo instead (tick
   "Copy items if needed" off, and add it to the `SeedlingWidget` target only).
4. Select the **Runner** target → Signing & Capabilities → **+ Capability** →
   **App Groups** → add `group.dev.bassiuz.seedling`.
5. Do the same for the **SeedlingWidget** target. Both must have the identical
   group, or the widget reads an empty container and shows the placeholder.
6. Set the widget target's deployment target to **iOS 15** to match the app.

## Checking it

Run the app on the phone once so it writes data, then long-press the home
screen → **+** → Seedling → Today.

If the widget shows "09:00 Dentist appointment" and two invented tasks, it is
rendering the placeholder — that means the App Group is missing or misspelled on
one of the two targets, which is the usual cause.

## What the app sends

`WidgetPublisher` writes one JSON blob under `seedling_today`:

```json
{"dayKey":"2026-07-27","next":"09:00 Dentist appointment",
 "tasks":["Edit the onboarding copy"],"remaining":2}
```

The shape is built by `buildWidgetPayload` in `lib/logic/widget_payload.dart`
and covered by `test/logic/widget_payload_test.dart`, so changing it is safe to
do test-first.
