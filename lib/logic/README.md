Pure business-logic helpers with no Flutter or Firebase dependencies.

- `day_key.dart` — `yyyy-MM-dd` day-key string helpers: `dayKeyOf`, `dateOfKey`, `addDays`, `todayKey`.
- `rollover.dart` — which day pages a task appears on and how its checkbox reads there: `taskVisibleOn`, `checkStateOn`, `tasksForDay`.
- `blacklist.dart` — which calendar events a day shows: `isHidden`,
  `visibleEvents` (with a reveal mode so a wrong hide can be undone).
- `week_key.dart` — ISO week keys (`2026-W31`), week bounds, and which week a
  review written on a given day belongs to.
- `markdown.dart` — renders days, reviews, someday lists and tags as Markdown
  for the vault, plus the paths each file belongs at.
- `widget_payload.dart` — builds what the home-screen widget shows: the next
  timed thing and the first few open tasks.
