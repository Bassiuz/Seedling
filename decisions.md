# Decisions

- **Firestore-only, no local DB** — design doc choice: Firestore's offline persistence gives us local-first behavior for free, so a separate local database adds nothing but sync complexity.
- **No state-management package** — StreamBuilder + setState is enough at this app's size; a package would add ceremony without benefit.
- **Fonts: Source Serif 4 (display) + Source Sans 3 (body)** — copied from Moxify; the design doc leaves the final font pairing open, and this pairing is proven and already licensed/bundled there.
- **Email/password auth for v1** — zero platform-specific configuration to ship; Apple/Google sign-in can be layered on later.
- **Tags store `iconIndex`, not an icon codepoint** — a dynamically constructed `IconData` defeats Flutter's icon tree-shaking and fails release builds without `--no-tree-shake-icons`. An index into a fixed icon list avoids that and mirrors how `colorIndex` already works. Both lists are ordering contracts, pinned by tests.
- **No `==`/`hashCode` on the models, no `Tag.copyWith`** — nothing needs them yet. Serialization tests compare `toMap()` output instead. Add them alongside the first caller that genuinely requires them.
- **`addDays` uses calendar math, not `Duration`** — a DST day is 23 or 25 hours, so `Duration(days: 1)` stalls on the autumn clock change and a day-by-day walk gets stuck there permanently.
- **macOS app sandbox disabled** — Firebase Auth needs keychain access, which a sandboxed app only gets via an entitlement requiring a macOS provisioning profile we do not have. Seedling runs locally on Bas's own Mac, so dropping the sandbox is cheaper than certificate management. Revisit if it ever ships through the Mac App Store.
- **Firestore rules are version-controlled in `firestore.rules`** — the project's default deny-all rules silently rejected every write, and `fake_cloud_firestore` cannot catch that class of bug because it has no rules engine.
- **All writes go through `_write()` in `DayPage`** — a rejected save used to look identical to a successful one. Failures now surface in a SnackBar.
- **Calendar is read-only** — Seedling is a lens on your calendar, not a calendar client, so events are shown and hidden but never edited. `CalendarSource` is an interface so day pages and their tests never touch a device.
- **Hide rules match a repeating series first, the exact title otherwise** — hiding "water the plants" once should hide it forever, not one occurrence at a time. Cmd-Shift-H reveals hidden events so a wrong hide can be undone.
- **macOS runs unsandboxed, so calendar access needs no extra entitlement** — but iOS does: `NSCalendarsUsageDescription` and `NSCalendarsFullAccessUsageDescription` are in both Info.plists.
- **A week review freezes the goals into itself** — a review is a record of that week, so it snapshots the template's goal blocks when it is created rather than reading them live. Editing goals later never rewrites history.
- **Review answers are keyed by the question text** — re-wording a prompt leaves the old answer under the old wording instead of silently re-labelling it.
- **Week keys are ISO-8601 (`2026-W31`)** — matches the vault filenames and sorts chronologically. Day-of-year is computed in UTC: a local `difference().inDays` loses an hour across DST and lands a week early.
