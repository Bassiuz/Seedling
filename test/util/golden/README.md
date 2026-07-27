# test/util/golden/

- `tolerance_golden_comparator.dart` — `LocalFileComparator` subclass that
  passes when the diff percentage is within a tolerance (set in
  `test/flutter_test_config.dart`).
- `load_fonts.dart` — loads real fonts (MaterialIcons, Roboto, SourceSans3,
  SourceSerif4, NotoColorEmoji) from `test/assets/fonts/` so goldens don't
  render Ahem boxes.
- `golden_utils.dart` — `GoldenSize` (canonical screen contexts),
  `configureSize`, `wrapApp` (MaterialApp + SeedlingTheme), and
  `goldenForSizes` (one golden per size).
- `infra_smoke_test.dart` — renders a plain `Text` at phone size; guards that
  the golden pipeline (config, comparator, fonts) keeps working.
- `goldens/` — golden baselines for tests in this folder.
