# test/assets/

Assets used only by tests (not bundled with the app).

- `fonts/` — real font files loaded by `test/util/golden/load_fonts.dart` so
  golden tests render actual glyphs instead of the Ahem placeholder font:
  MaterialIcons, Roboto, SourceSans3 (Regular/Medium/SemiBold/Bold),
  SourceSerif4 (SemiBold/SemiBoldItalic), NotoColorEmoji.
