# macOS signing

macOS sign-in is working. This is the record of what it needed, because the
error it produces points nowhere useful.

## The symptom

> An error occurred when accessing the keychain.

Firebase Auth keeps the signed-in session in the macOS **data protection
keychain**. An app may only use that keychain if it carries the
`com.apple.application-identifier` entitlement — and that entitlement only comes
from a **provisioning profile**.

## What it actually took

Three things, all of them necessary and none of them sufficient alone:

1. **The Mac registered in the developer account.** Done once from Xcode:
   Signing & Capabilities → Automatically manage signing → team `NSCP3LMJ94`.
   Before this there were 12 iOS profiles on the machine and zero macOS ones.
2. **A real keychain access group.** Xcode's "Keychain Sharing" capability
   writes an *empty* `<array/>`, which grants nothing and does not force a
   profile to be issued. Both entitlements files now name the group explicitly:

   ```xml
   <key>keychain-access-groups</key>
   <array>
       <string>$(AppIdentifierPrefix)dev.bassiuz.seedling</string>
   </array>
   ```
3. **Automatic signing throughout.** A leftover `CODE_SIGN_STYLE = Manual` with
   an empty `PROVISIONING_PROFILE_SPECIFIER` made the build look for a profile
   by a UUID that no longer existed:

   > Build input file cannot be found: …/b3f8dcbc-….provisionprofile

   Clearing the stale `DerivedData` for the project fixed the rest.

## What was ruled out along the way

Each of these was tested separately rather than assumed:

| Tried | Result |
|---|---|
| Turning the app sandbox off | Not the cause — sign-in still failed |
| Ad-hoc signature | Fails: `TeamIdentifier=not set` |
| Development certificate alone | Fails: a team identifier is not enough |
| Keychain Sharing with an empty group | Signs, but no `application-identifier` |

## Checking it still works

```
fvm flutter build macos --debug
codesign -d --entitlements :- build/macos/Build/Products/Debug/seedling.app
```

The signed binary must show all three:

```
com.apple.application-identifier = NSCP3LMJ94.dev.bassiuz.seedling
com.apple.developer.team-identifier = NSCP3LMJ94
keychain-access-groups = ['NSCP3LMJ94.dev.bassiuz.seedling']
```

If `com.apple.application-identifier` is missing, no profile was embedded and
sign-in will fail with the keychain error again.

## Note on the certificate

The app signs with **Apple Development: Bas de Vaan (WPLALAP244)**, whose team
is `NSCP3LMJ94` — the same team the iPhone build uses. The other development
certificate on this machine belongs to team `DR72S3PTUQ`, which is a different
account.
