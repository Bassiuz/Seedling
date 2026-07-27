# test/theme/

Tests for the design system in `lib/theme/`.

- `theme_gallery_test.dart` — asserts the exact contents and order of the
  palette's `tagColors` (a persisted `Tag.colorIndex` contract), that every
  text style names a bundled font family and color, and that no Material purple
  survives in the color scheme; then renders a gallery of all 17 swatches and
  one line of each key text style as a golden.
- `goldens/` — golden baselines for tests in this folder.
