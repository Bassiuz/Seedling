# Engineering Notes

## Toolchain

- Flutter **3.44.2** managed via [fvm](https://fvm.app). There is no global `flutter` on PATH — always prefix commands with `fvm`:
  - Run tests: `fvm flutter test`
  - Run the app: `fvm flutter run -d macos`
  - Analyze: `fvm flutter analyze`
  - Pub commands: `fvm flutter pub add <pkg>` / `fvm dart ...`

## Firebase

- Firebase project: `seedling-461b0`
- Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`

## Planned `lib/` layout

```
lib/
  models/    # plain data classes (plants, entries, ...)
  logic/     # pure business logic, no Flutter/Firebase imports
  data/      # Firestore repositories and auth service
  theme/     # colors, typography, ThemeData
  screens/   # one file per screen
  widgets/   # shared/reusable widgets
  main.dart
```

## Testing

- Unit/widget tests live in `test/`, mirroring the `lib/` structure.
- Firestore-dependent code is tested against `fake_cloud_firestore` (dev dependency).
- Golden tests: run `fvm flutter test` to check goldens; regenerate them after
  intentional visual changes with:

  ```
  fvm flutter test --update-goldens
  ```

  Review the regenerated PNGs in the diff before committing.
