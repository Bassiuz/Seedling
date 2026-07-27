# Decisions

- **Firestore-only, no local DB** — design doc choice: Firestore's offline persistence gives us local-first behavior for free, so a separate local database adds nothing but sync complexity.
- **No state-management package** — StreamBuilder + setState is enough at this app's size; a package would add ceremony without benefit.
- **Fonts: Source Serif 4 (display) + Source Sans 3 (body)** — copied from Moxify; the design doc leaves the final font pairing open, and this pairing is proven and already licensed/bundled there.
- **Email/password auth for v1** — zero platform-specific configuration to ship; Apple/Google sign-in can be layered on later.
- **Tags store `iconIndex`, not an icon codepoint** — a dynamically constructed `IconData` defeats Flutter's icon tree-shaking and fails release builds without `--no-tree-shake-icons`. An index into a fixed icon list avoids that and mirrors how `colorIndex` already works. Both lists are ordering contracts, pinned by tests.
- **No `==`/`hashCode` on the models, no `Tag.copyWith`** — nothing needs them yet. Serialization tests compare `toMap()` output instead. Add them alongside the first caller that genuinely requires them.
- **`addDays` uses calendar math, not `Duration`** — a DST day is 23 or 25 hours, so `Duration(days: 1)` stalls on the autumn clock change and a day-by-day walk gets stuck there permanently.
