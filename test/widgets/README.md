# test/widgets

Golden and behaviour tests for `lib/widgets/`. Goldens live in `goldens/`.

- `day_header_test.dart` — the header on today and on a day outside the three
  shortcuts, that it writes the date in words, reports jumps, and highlights
  the matching shortcut (or none).
- `task_tile_test.dart` — every tile state in one gallery golden (open, timed,
  tagged, carried, checked here, done later), plus the origin/completion notes
  and that a tile finished on a later day ignores taps.
- `blocks_test.dart` — the three blocks stacked, filled (phone and e-ink) and
  empty; the add field's submit/clear and blank-input handling; and that the
  note adopts text for a new day without resetting the field mid-sentence.
