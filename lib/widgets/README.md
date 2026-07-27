# lib/widgets

The pieces a day page is built from. All of them are presentational: they take
data and callbacks, and never reach for the repo themselves, so every one can
be golden-tested without Firebase.

- `day_header.dart` — `DayHeader`: the yesterday/today/tomorrow shortcut pill
  and the written-out date. `DayShortcut` is one segment of that pill.
- `task_tile.dart` — `TaskTile`: one task, with `TaskCheckbox` (the big round
  one) and a quiet footnote line for time, tag and origin. A task finished on a
  later day is drawn as faded history and ignores taps.
- `tag_chip.dart` — `TagChip`: a tag as a small outlined chip, plus
  `colorOf`/`iconOf` for anything else that needs a tag's colour or icon.
- `block_frame.dart` — `BlockFrame`: the shared heading-plus-hairline chrome
  every day-page section sits in. `EmptyNote` is the grey line an empty one
  shows.
- `timed_block.dart` — `TimedBlock`: the day's timed tasks in clock order.
- `tasks_block.dart` — `TasksBlock`: the day's untimed tasks, with the add line.
- `add_task_field.dart` — `AddTaskField`: the type-a-new-task row.
- `note_block.dart` — `NoteBlock`: the daily note on ruled paper. Its font size
  and line height are fixed constants because the rules are painted to match.
- `questions_block.dart` — `QuestionsBlock`: the day's quick check-offs, which
  fold into an "All answered · 2/2" line once complete. `QuestionCheck` is the
  small circle a yes/no question uses.
- `time_sheet.dart` — `TimeSheet`: logs work against a task in quarter-hour
  steps, showing the day's total and the all-days total. `TimeSheet.format`
  renders minutes as "1h 30m" for the tile footnote too.
