# lib/data

The Firestore boundary. Firestore types do not escape this folder — callers
work with `Task`, `Tag` and plain strings.

- `seedling_repo.dart` — `SeedlingRepo`: reads and writes one signed-in user's
  tasks, tags and daily notes under `users/{uid}/`. Storage only; which tasks
  belong on a given day is decided in `lib/logic/rollover.dart`.
- `calendar_source.dart` — `CalendarSource` and its three implementations:
  `DeviceCalendar` (EventKit / Android provider, read-only), `NoCalendar` for
  platforms that cannot see one, and `FakeCalendar` for tests.
- `settings_store.dart` — per-device settings, currently the e-ink display mode.
