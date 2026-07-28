# Engineering Notes

## Toolchain

- Flutter **3.44.2** managed via [fvm](https://fvm.app). There is no global `flutter` on PATH — always prefix commands with `fvm`:
  - Run tests: `fvm flutter test`
  - Run the app: `fvm flutter run -d macos`
  - Analyze: `fvm flutter analyze`
  - Pub commands: `fvm flutter pub add <pkg>` / `fvm dart ...`

## Firebase

- Firebase project: `seedling-461b0`. Config in `lib/firebase_options.dart`,
  regenerate with `flutterfire configure --project=seedling-461b0` (needs
  `~/.pub-cache/bin` and the fvm SDK's `bin` on PATH).
- Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`.
- **Firebase Authentication must be enabled in the console** (Build →
  Authentication → Get started → Email/Password). Without it the app builds and
  runs but sign-in fails with `CONFIGURATION_NOT_FOUND`. Enabling it through the
  Identity Platform API instead requires billing; the console toggle does not.
- macOS needs `com.apple.security.network.client` in **both**
  `macos/Runner/*.entitlements`, or Firestore silently fails to reach the
  network in the sandbox.
- **macOS needs a provisioning profile for sign-in to work — see
  `docs/macos-signing.md`.** Firebase Auth uses the data protection keychain,
  which requires the `com.apple.application-identifier` entitlement that only a
  profile carries. That means automatic signing with team `NSCP3LMJ94`, the Mac
  registered in the developer account, and a *named* keychain access group —
  Xcode's empty `<array/>` grants nothing.
- **Firestore rules live in `firestore.rules`** and are deployed with
  `firebase deploy --only firestore:rules`. The project shipped with the
  production default (`allow read, write: if false`), which silently rejected
  every save. `fake_cloud_firestore` has no rules engine, so no test can catch
  this — check the console or deploy the rules after creating a database.
- iOS is pinned to deployment target **15.0** (`ios/Podfile` and all three
  `IPHONEOS_DEPLOYMENT_TARGET` entries in `Runner.xcodeproj`) because
  `cloud_firestore` requires it. Flutter's default of 13.0 fails at
  `pod install`; keep the Podfile and the Xcode project in step.

## Android

`pubspec.yaml` pins **`path_provider_android` to 2.2.23** in
`dependency_overrides`. Version 2.3.x pulls in `jni`, whose `android/build.gradle`
skips applying the Kotlin plugin on AGP 9 and then uses its `kotlin { }`
extension anyway:

```groovy
if (agpMajor < 9) { apply plugin: 'kotlin-android' }
...
kotlin { compilerOptions { … } }
```

That fails every AGP 9 build with *"Could not find method kotlin()"*. Our project
is on AGP 9.0.1. `path_provider` reaches us only through `home_widget`. Remove
the override once `jni` guards the usage as well as the plugin.

## Calendar

`device_calendar` supports **iOS and Android only**. The iPhone reads EventKit
and publishes a 60-day window to `users/{uid}/calendarMirror`; the Mac and the
BigMe read that mirror because neither can see iCloud themselves.
`DeviceCalendar.supported` is the one switch deciding which path a device takes.
Setup is in `docs/calendar-setup.md`.

## Running from VS Code

`.vscode/settings.json` points the Dart extension at `.fvm/flutter_sdk`; without
it there is no SDK to find, since nothing is installed globally.
`.vscode/launch.json` offers debug, profile, and a release configuration that
installs a standalone build on a device.

## `lib/` layout

See `lib/README.md`. Dependencies only point downward:
`screens/` → `widgets/` → `theme/`, with `data/` → `models/` and `logic/` →
`models/`. Nothing outside `data/` imports Firestore.

## Testing

- Unit/widget tests live in `test/`, mirroring the `lib/` structure.
- Firestore-dependent code is tested against `fake_cloud_firestore` (dev dependency).
- Golden tests: run `fvm flutter test` to check goldens; regenerate them after
  intentional visual changes with:

  ```
  fvm flutter test --update-goldens
  ```

  Review the regenerated PNGs in the diff before committing.

- Goldens are rendered at four canonical sizes (`test/util/golden/golden_utils.dart`):
  `phone`, `eink` (BigMe B7), `macNarrow` and `mac`. Widgets with several visual
  states are captured as one gallery image rather than one file per state, so a
  change is reviewed in a single picture.

## Smoke-running the macOS app

`fvm flutter run -d macos` normally. To screenshot a running build without
screen-recording permission, connect to its Dart VM service and call
`_flutter.screenshot` — the service URI is printed on stdout at launch.
