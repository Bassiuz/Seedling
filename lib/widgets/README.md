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
