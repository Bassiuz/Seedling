# test/data

- `seedling_repo_test.dart` — exercises every `SeedlingRepo` method against
  `FakeFirebaseFirestore`, asserting on the resulting stored state or stream
  emission. Covers note merging (so a day document keeps its other fields) and
  that one user's repo cannot see another user's data.
