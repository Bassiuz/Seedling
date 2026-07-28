import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data/calendar_source.dart';
import 'data/seedling_repo.dart';
import 'data/settings_store.dart';
import 'screens/day_page.dart';
import 'screens/sign_in_screen.dart';
import 'theme/seedling_theme.dart';
import 'widgets/dismiss_keyboard.dart';

/// Signed out you get the sign-in form; signed in you get your days.
class SeedlingApp extends StatelessWidget {
  const SeedlingApp({
    super.key,
    required this.auth,
    required this.firestore,
    required this.settings,
    required this.calendar,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final SettingsStore settings;
  final CalendarSource calendar;

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when the display mode changes, which is the point:
    // e-ink mode is a different ThemeData, not a flag widgets check.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Seedling',
        debugShowCheckedModeBanner: false,
        theme: SeedlingTheme.of(eink: settings.einkMode),
        builder: (context, child) => DismissKeyboard(child: child!),
        // Firebase restores a persisted session while initializeApp() runs, so
        // currentUser is already authoritative on the first frame. Seeding it
        // avoids a blank frame on every launch — sign-in itself persists on its
        // own: on iOS, macOS and Android the session is always kept and
        // setPersistence is web-only, so you sign in once per device.
        home: StreamBuilder<User?>(
          stream: auth.authStateChanges(),
          initialData: auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) return SignInScreen(auth: auth);
            final repo = SeedlingRepo(firestore, user.uid);
            return DayPage(
              repo: repo,
              settings: settings,
              // Only devices told to read their own calendar do so. Being
              // Android is not enough — the BigMe has no iCloud account.
              calendar: settings.readsDeviceCalendar &&
                      DeviceCalendar.supported
                  ? calendar
                  : MirrorCalendar(repo.readCalendarMirror),
              publishesCalendar:
                  settings.readsDeviceCalendar && DeviceCalendar.supported,
              onSignOut: auth.signOut,
              signedInAs: user.email,
            );
          },
        ),
      ),
    );
  }
}
