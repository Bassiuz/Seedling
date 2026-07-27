# test/screens

- `day_page_test.dart` — `DayView` goldens at all four canonical sizes plus an
  empty day, and `DayPage` driven against `FakeFirebaseFirestore`: opening on
  today, checking a task storing that day, unchecking clearing it, and typing a
  task adding it to the day on screen.
