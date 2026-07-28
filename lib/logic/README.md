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
- `event_time.dart` — turning a calendar instant into local wall-clock time
  (`localEventTime`, `clockOf`) and deciding what counts as overdue.
- `timed_entries.dart` — merges appointments and timed tasks into the one
  chronological list the Timed block draws.
- `recent_emoji.dart` — the most-recently-used emoji list (`promoteEmoji`) and
  normalising typed input to one grapheme cluster (`firstEmoji`).
- `mirror_doc_id.dart` — encodes a calendar event id into something Firestore
  will accept as a document id. EventKit ids contain slashes and the reserved
  `__…__` shape, either of which is fatal.
- `duration_input.dart` — reads a typed duration into minutes: a bare number
  under 15 is hours, from 15 up is minutes, and `3.5`, `3:15`, `90m` all work.
