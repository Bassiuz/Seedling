# test/data

- `seedling_repo_test.dart` — exercises every `SeedlingRepo` method against
  `FakeFirebaseFirestore`, asserting on the resulting stored state or stream
  emission. Covers note merging (so a day document keeps its other fields) and
  that one user's repo cannot see another user's data.
- `blacklist_repo_test.dart` — hiding accumulates keys, unhiding removes one,
  duplicates are ignored, and one user cannot see another's hidden events.
- `vault_exporter_test.dart` — writes into a temp folder: files land under the
  right paths, rewriting replaces rather than appends, folders are created.
- `vault_mirror_test.dart` — debouncing a burst of keystrokes into one write,
  skipping unchanged rebuilds, flushing on the way out, and swallowing a failed
  write rather than throwing at the caller.
- `mirror_live_test.dart` — the mirror driven from real repo data, checking the
  file that lands on disk.
- `event_done_repo_test.dart` — ticking a calendar event off is stored per day,
  so a repeating event done today is still waiting tomorrow.
- `recent_emoji_repo_test.dart` — the strip is stored newest-first, capped at
  ten, and scoped to its own user.
- `calendar_mirror_repo_test.dart` — publishing replaces its window rather than
  accumulating, events outside it are untouched, and reads are scoped per user.
