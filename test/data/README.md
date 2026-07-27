# test/data

- `seedling_repo_test.dart` — exercises every `SeedlingRepo` method against
  `FakeFirebaseFirestore`, asserting on the resulting stored state or stream
  emission. Covers note merging (so a day document keeps its other fields) and
  that one user's repo cannot see another user's data.
- `blacklist_repo_test.dart` — hiding accumulates keys, unhiding removes one,
  duplicates are ignored, and one user cannot see another's hidden events.
- `vault_exporter_test.dart` — writes into a temp folder: files land under the
  right paths, rewriting replaces rather than appends, folders are created.
