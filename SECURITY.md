# Security

## The Firebase API keys in this repository are not secrets

`lib/firebase_options.dart`, `android/app/google-services.json` and the two
`GoogleService-Info.plist` files contain values that look like credentials and are
not. A Firebase API key is a **project identifier**, not an authorisation: it names
which project a request is for. Google
[documents them as safe to embed in client code](https://firebase.google.com/docs/projects/api-keys),
and they ship inside every copy of the app anyway — anyone with the `.apk` has had
them all along.

GitHub's secret scanner flags them because it cannot tell a Firebase client key from
a Google Cloud server key. The alert is correct about what it found and wrong about
what it means.

## What actually protects the data

[`firestore.rules`](firestore.rules). Every document lives under `users/{uid}` and is
readable and writable only by that user:

```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
  match /{document=**} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
}
```

There is no shared or public collection. Someone holding the API key can reach the
project, but they cannot read a single document belonging to anyone else.

## What the key does let a stranger do

Create an account. The key can call Identity Toolkit, so with email/password sign-up
enabled anyone could register in the project — landing in their own empty subtree,
seeing nothing of anyone else's, but consuming the project's quota.

If you fork this and point it at your own Firebase project, close that off once your
own account exists:

- **Firebase Console → Authentication → Settings → User actions → uncheck "Enable
  create (sign-up)".** A one-person app needs sign-up exactly once.
- Optionally add [App Check](https://firebase.google.com/docs/app-check) so only your
  own builds can talk to the project at all.
- Restrict the keys in **Google Cloud Console → APIs & Services → Credentials** to
  your bundle identifiers.

## What genuinely never belongs here

Signing keys, provisioning profiles, service-account JSON and API tokens for other
people's systems. [`.gitignore`](.gitignore) refuses the usual shapes, and the Jira
API token the timesheet uses is kept in the device keychain via
`flutter_secure_storage` — never in Firestore, never in this repository.

Found something that is a real secret? Open an issue without the secret in it, and
say where to look.
