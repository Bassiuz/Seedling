# Phases 2–4 progress

Working checklist for the rest of the design doc
(`docs/plans/2026-07-27-seedling-design.md`). Update the state column as each
piece lands. Branch `phase-1`.

| # | Piece | State |
|---|-------|-------|
| 1 | Settings screen, e-ink display mode, sign out | **done** |
| 2 | Daily questions (configurable, collapse when answered) | **done** |
| 3 | Someday lists per tag + pull-top-3-5 flow | **done** |
| 4 | Time entries in 15-minute steps | **done** |
| 5 | Calendar (EventKit) agenda + blacklist with reveal | **done** |
| 6 | Week review templates with goal snapshots | **done** |
| 7 | Markdown vault export (macOS) | **done** |
| 8 | iPhone home-screen widget | **done** — Dart side built and tested; Xcode target needs adding by hand, see `docs/ios-widget-setup.md` |

## Conventions (unchanged from phase 1)

- TDD, golden test every widget and screen, README.md in every folder.
- `fvm flutter analyze` clean and `fvm flutter test` green before each commit.
- Verify against the real macOS app when a change is worth seeing; test account
  `test@sdevaan.nl` / `123456`.

## Notes for whoever picks this up

- Firestore rules are in `firestore.rules`; deploy with
  `firebase deploy --only firestore:rules`.
- The macOS app runs unsandboxed so Firebase Auth can reach the keychain.
- Driving the macOS app: build it, run the binary, and use the Dart VM service
  `_flutter.screenshot` RPC for screenshots. AppleScript keystrokes are
  unreliable — prefer widget tests for behaviour and reserve the real app for
  confirming a screen looks right.
