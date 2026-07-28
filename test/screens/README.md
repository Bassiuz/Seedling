# test/screens

- `day_page_test.dart` — `DayView` goldens at all four canonical sizes plus an
  empty day, and `DayPage` driven against `FakeFirebaseFirestore`: opening on
  today, checking a task storing that day, unchecking clearing it, and typing a
  task adding it to the day on screen.
- `sign_in_screen_test.dart` — the form's goldens (phone, Mac, and with an
  error), that it trims the email, and that it cannot be submitted twice.
- `settings_screen_test.dart` — settings goldens on phone, Mac and e-ink, the
  toggle and sign-out callbacks, and that the e-ink colour set really is white
  paper with no mid-grey text.
- `someday_screen_test.dart` — goldens filled and empty, the grouping rule, and
  that promoting really creates the task and removes the parked item.
- `calendar_test.dart` — the timed block with appointments, hide and reveal, and
  one day-page test proving events land on the day. A second DayPage test in
  this file never settles, so hiding is covered at repo level instead.
- `week_review_test.dart` — goldens written and blank, that a new review freezes
  the goals, and answering, adding and removing observations.
- `back_line_test.dart` — that settings, tags and the week review can actually
  be left again, including the week review's loading frame, which used to be a
  blank page with no way out. On the Mac there is no edge-swipe, so without the
  arrow these are dead ends.
- `task_menu_test.dart` — that an existing task can be given a tag and have its
  time set or removed, and that "Remove the time" only appears when there is one.
