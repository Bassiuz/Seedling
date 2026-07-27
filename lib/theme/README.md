# theme/

The Seedling design system: color tokens and the app theme built from them.

- `seedling_palette.dart` — `SeedlingPalette`: the e-ink-safe color tokens from
  the design doc (ink/grays, 11 accents, `paper` + `paperLine`), plus
  `tagColors`, the accent list `Tag.colorIndex` points into.
- `seedling_theme.dart` — `SeedlingTheme.light()`: the notebook theme. Paper
  surfaces, ink text, SourceSerif4 headers (always w600 — the only bundled
  cut), SourceSans3 body/labels, 12px rounded cards/buttons/inputs.
