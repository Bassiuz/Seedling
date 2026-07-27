# test/assets/fonts

Font binaries loaded into the golden-test renderer by
`test/util/golden/load_fonts.dart`. Without them every golden renders tofu
boxes.

- `SourceSans3-{Regular,Medium,SemiBold,Bold}.ttf` — the app's body font.
- `SourceSerif4-SemiBold{,Italic}.ttf` — the app's display font. Only the
  SemiBold cut is bundled, which is why serif styles are all `w600`.
- `MaterialIcons-Regular.otf` — icons.
- `Roboto-Regular.ttf` — Flutter's default fallback, taken from the SDK's
  `material_fonts` cache.
- `NotoColorEmoji-Regular.ttf` — emoji fallback.

If a golden ever renders boxes, check these are real fonts
(`file test/assets/fonts/*`) — `FontLoader` ignores invalid bytes silently.
