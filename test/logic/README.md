Tests for the pure logic helpers in `lib/logic/`.

- `day_key_test.dart` — padding, roundtrip, and month/year/DST boundary tests for the day-key helpers.
- `rollover_test.dart` — the carry-forward rule, including Bas's own worked
  example (planned Tuesday, ticked off on Wednesday's page while it is
  Thursday) and the anomaly where `completedOnDate` precedes the planned date.
- `blacklist_test.dart` — series-vs-title matching, dropping hidden events,
  reveal, and the all-day-before-timed ordering.
