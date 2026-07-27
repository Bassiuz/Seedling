# lib/models

Plain Dart data classes for everything Seedling stores. No Firestore imports —
they speak `Map<String, dynamic>`, so the repo layer owns all persistence and
the models stay testable without a backend.

- `task.dart` — `Task`: a to-do item. Day-key dates, an optional time and tag,
  and `completedOnDate` recording which day page it was checked off on.
- `tag.dart` — `Tag`: a project label. Stores indexes into the palette and icon
  lists rather than a colour or codepoint.
- `daily_question.dart` — `DailyQuestion`: a daily check-off, either a plain
  check or a set of choice chips. Deactivating one keeps past answers.
- `someday_item.dart` — `SomedayItem`: an idea parked against a project, with a
  priority so the pull-into-today flow can offer the best few.
- `calendar_event.dart` — `CalendarEvent`: one appointment read from the device
  calendar. `hideKey` is what a blacklist rule matches on.
