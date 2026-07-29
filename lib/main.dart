import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'data/calendar_source.dart';
import 'data/widget_publisher.dart';
import 'data/settings_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline persistence is what makes this local-first: the app opens and
  // works with no network, and Firestore reconciles when it comes back.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Ticking something off on the home screen wakes a background isolate.
  await HomeWidget.registerInteractivityCallback(widgetTapped);

  runApp(
    SeedlingApp(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      settings: await SettingsStore.open(),
      calendar: DeviceCalendar(),
    ),
  );
}
