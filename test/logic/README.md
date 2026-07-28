Tests for the pure logic helpers in `lib/logic/`.

- `day_key_test.dart` — padding, roundtrip, and month/year/DST boundary tests for the day-key helpers.
- `rollover_test.dart` — the carry-forward rule, including Bas's own worked
  example (planned Tuesday, ticked off on Wednesday's page while it is
  Thursday) and the anomaly where `completedOnDate` precedes the planned date.
- `blacklist_test.dart` — series-vs-title matching, dropping hidden events,
  reveal, and the all-day-before-timed ordering.
- `week_key_test.dart` — ISO numbering including the year-boundary weeks, week
  bounds, and which week a review belongs to.
- `markdown_test.dart` — front matter, checkboxes, task annotations, the agenda,
  answered questions, verbatim notes, reviews, and the file paths.
- `widget_payload_test.dart` — which item counts as "next", completed tasks
  being left off, the overflow count, and the JSON shape the widget reads.
- `event_time_test.dart` — the UTC-to-local conversion that fixes appointments
  showing two hours early, all-day events keeping their date, and the overdue
  rule (today only, and not at the current minute).
- `timed_entries_test.dart` — interleaving by clock, all-day events first, and
  ids that do not collide between an event and a task of the same name.
