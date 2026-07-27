# test/models

- `models_test.dart` — serialization roundtrips (including all-null optionals
  and documents missing keys), the `isCompleted`/`isTimed` getters, and
  `Task.copyWith` — in particular that `clearCompleted` nulls
  `completedOnDate` while omitting the field preserves it.
