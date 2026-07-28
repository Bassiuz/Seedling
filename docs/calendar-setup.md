# Turning on calendar sync

## The short version

Run Seedling on your **iPhone** once and allow calendar access. That is the
whole setup — the Mac and the BigMe pick it up from there.

## Why the phone has to do it

`device_calendar`, the plugin Seedling reads appointments with, ships
implementations for **iOS and Android only**. There is no macOS one, so on the
Mac the method channel does not exist and no calendar can be read, no matter
what permissions you grant. The BigMe has the opposite problem: it is Android
and *could* read a calendar, but it cannot see iCloud.

So the phone is the only device that can read your Apple calendar, and it
publishes what it finds:

```
iPhone ──reads EventKit──▶ Firestore users/{uid}/calendarMirror ──▶ Mac, BigMe
```

The window is 60 days back and 60 days forward, refreshed whenever the app
starts on the phone. Publishing **replaces** that window rather than merging
into it, so an appointment you cancel or move disappears from the other devices
instead of lingering.

## Step by step

1. Build and run on the iPhone: `fvm flutter run -d <device> --release`.
2. Open the app. iOS asks for calendar access on the first day page — allow it.
   The prompt text lives in `ios/Runner/Info.plist`.
3. Your appointments appear in the Timed block, interleaved with timed tasks.
4. Open Seedling on the Mac. The same appointments are there, read from the
   mirror.

If you refused the prompt, iOS will not ask again: Settings → Privacy &
Security → Calendars → Seedling.

## What you can do with an appointment

- **Tick it off.** The tick lives in Seedling; your calendar is never written
  to, so nothing leaks back into iCloud or Outlook.
- **Long-press to hide it.** Repeating events are matched by their series, so
  hiding "water the plants" once hides every occurrence. ⌘⇧H reveals hidden
  events with an undo, in case you hid the wrong thing.

## Known limits

- The Mac shows what the phone last published. Open the app on the phone after
  a big calendar change and the Mac catches up.
- Only calendars the phone can see are mirrored. A work calendar that is not on
  your phone will not appear.
- If macOS ever gets a `device_calendar` implementation, `DeviceCalendar.supported`
  in `lib/data/calendar_source.dart` is the single place that decides which
  devices read directly and which read the mirror.
