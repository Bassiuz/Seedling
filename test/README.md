# test/

## Golden testing

Golden (screenshot) tests compare rendered widgets pixel-by-pixel against
checked-in PNG baselines.

### How it works here

- `flutter_test_config.dart` runs before every test file. It loads real fonts
  and installs a `ToleranceGoldenComparator` with threshold **0.0** (exact
  match). It throws if the default comparator is not a `LocalFileComparator`
  (e.g. when run on an unsupported platform).
- **Tolerance**: `ToleranceGoldenComparator`
  (`util/golden/tolerance_golden_comparator.dart`) passes when the comparison
  passes outright or the diff percentage is `<= diffTolerance`. The threshold
  lives in `flutter_test_config.dart`; bump it only if cross-machine
  antialiasing differences ever force it.
- **Fonts**: `flutter_test` renders with a placeholder font (solid boxes) by
  default. `util/golden/load_fonts.dart` loads MaterialIcons, Roboto,
  SourceSans3 (400/500/600/700), SourceSerif4 (600 normal+italic) and
  NotoColorEmoji from `test/assets/fonts/` so goldens show real glyphs.
  Caveat: the test engine pre-registers the family name `Roboto` as the
  placeholder font and a dynamically loaded real Roboto does NOT override it
  (verified empirically on Flutter 3.44). Text styled with an explicit or
  theme-derived `Roboto` family still renders boxes; `SeedlingTheme` uses
  `SourceSans3`, so themed widgets render real glyphs. Always render goldens
  through `wrapApp`/`SeedlingTheme`, not a bare `MaterialApp` default theme.
- **Sizes**: use `goldenForSizes` from `util/golden/golden_utils.dart` to
  render one golden per canonical screen context (phone, eink, macNarrow,
  mac). Baselines land in a `goldens/` folder next to the test file.

### Commands

```sh
# run all tests (goldens compared against baselines)
fvm flutter test

# (re)generate golden baselines after an intentional UI change
fvm flutter test --update-goldens

# regenerate for a single file
fvm flutter test --update-goldens test/path/to/some_test.dart
```

Review regenerated PNGs in the diff before committing — an unintended visual
change that gets `--update-goldens`'d becomes the new baseline.

On failure, diff images are written to `test/**/failures/`.
