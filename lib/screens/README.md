# lib/screens

Whole screens, assembled from `lib/widgets/`.

- `day_page.dart` — two classes:
  - `DayView`, purely presentational: one day laid out for the width it is
    given (stacked under 600pt, two columns to 1000pt, three above). Golden
    tests render this, so no layout needs Firebase to be checked.
  - `DayPage`, the live screen: an endless `PageView` of days anchored on
    today, streaming tasks, tags and the note from `SeedlingRepo`, with the
    check/uncheck rule, debounced note saves, and the snooze/delete menu.
- `sign_in_screen.dart` — `SignInForm` (pure, golden-tested) and
  `SignInScreen`, which signs in and creates the account on first use.
- `settings_screen.dart` — `SettingsView` (pure, golden-tested) and
  `SettingsScreen`: the e-ink display toggle, a link to tags, and sign out.
