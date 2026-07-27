# Decisions

- **Firestore-only, no local DB** — design doc choice: Firestore's offline persistence gives us local-first behavior for free, so a separate local database adds nothing but sync complexity.
- **No state-management package** — StreamBuilder + setState is enough at this app's size; a package would add ceremony without benefit.
- **Fonts: Source Serif 4 (display) + Source Sans 3 (body)** — copied from Moxify; the design doc leaves the final font pairing open, and this pairing is proven and already licensed/bundled there.
- **Email/password auth for v1** — zero platform-specific configuration to ship; Apple/Google sign-in can be layered on later.
