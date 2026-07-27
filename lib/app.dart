import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data/seedling_repo.dart';
import 'screens/day_page.dart';
import 'screens/sign_in_screen.dart';
import 'theme/seedling_theme.dart';
import 'widgets/dismiss_keyboard.dart';

/// Signed out you get the sign-in form; signed in you get your days.
class SeedlingApp extends StatelessWidget {
  const SeedlingApp({super.key, required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seedling',
      debugShowCheckedModeBanner: false,
      theme: SeedlingTheme.light(),
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
          return DayPage(repo: SeedlingRepo(firestore, user.uid));
        },
      ),
    );
  }
}
