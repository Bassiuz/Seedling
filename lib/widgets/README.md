# lib/widgets

The pieces a day page is built from. All of them are presentational: they take
data and callbacks, and never reach for the repo themselves, so every one can
be golden-tested without Firebase.

- `day_header.dart` — `DayHeader`: the yesterday/today/tomorrow shortcut pill
  and the written-out date. `DayShortcut` is one segment of that pill.
