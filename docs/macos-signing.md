# macOS sign-in needs one thing from you

The Mac app builds and runs, but signing in fails with:

> An error occurred when accessing the keychain.

This is not a bug in Seedling. It is macOS refusing the app access to the
keychain, and it needs a one-time action on your Apple developer account that
cannot be done from the command line.

## Why

Firebase Auth stores the signed-in session in the **data protection keychain**.
On macOS, an app may only use that keychain if it carries an
`application-identifier` entitlement — which comes from a **provisioning
profile**. No profile, no keychain, no sign-in.

Getting a profile needs your Mac registered in the developer account, and it
never has been:

```
$ ls ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/
12 iOS profiles, 0 macOS profiles
```

What has already been ruled out, by testing rather than guessing:

| Tried | Result |
|---|---|
| Turning the sandbox off | Still fails — the sandbox was never the cause |
| Ad-hoc signature | Fails: `TeamIdentifier=not set` |
| Real development certificate, team `NSCP3LMJ94` | Still fails — a team alone is not enough |
| Adding `keychain-access-groups` | Will not sign: "No profiles for 'dev.bassiuz.seedling'" |
| `xcodebuild -allowProvisioningUpdates` | "Device 'Bas's MacBook Pro' isn't registered in your developer account" |

## The fix, about two minutes

1. Open `macos/Runner.xcworkspace` in Xcode.
2. **Xcode → Settings → Accounts**. Make sure the Apple ID behind team
   **NSCP3LMJ94** is signed in. (That is the team the iPhone build already
   uses.)
3. Select the **Runner** target → **Signing & Capabilities**.
4. Tick **Automatically manage signing** and pick that team. Xcode will offer to
   register this Mac — accept. That is the step that has never happened.
5. Click **+ Capability** and add **Keychain Sharing**. Leave the default group.
6. Build once from Xcode (⌘B) so the profile is created.

After that, `fvm flutter run -d macos` works and sign-in succeeds.

Then put the entitlement back in the repo so it survives a clean checkout — add
this to **both** `macos/Runner/DebugProfile.entitlements` and
`Release.entitlements`:

```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)dev.bassiuz.seedling</string>
</array>
```

It is deliberately not committed right now, because with no profile on this
machine it makes `flutter build macos` fail outright — a broken build is worse
than a build that cannot sign in.

## If you would rather not

Everything works on iPhone and Android today; only macOS needs this. The other
way round it would mean replacing Firebase Auth with hand-rolled REST auth on
macOS only — and that does not work either, because `cloud_firestore` takes its
credentials from `firebase_auth`, so the whole data layer would have to be
replaced on that one platform. Not worth it for a two-minute Xcode step.
