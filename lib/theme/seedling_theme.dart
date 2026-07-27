import 'package:flutter/material.dart';

/// Placeholder theme. Task 2 (design system) replaces this with the real
/// Seedling theme (SourceSans3/SourceSerif4 typography, color scheme, etc.).
///
/// Already uses SourceSans3 as the base font family: it is the app's real
/// body/UI font (declared in pubspec.yaml), and in widget tests the engine's
/// built-in 'Roboto' mapping cannot be overridden with a real font, so
/// goldens would render placeholder boxes without it.
class SeedlingTheme {
  static ThemeData light() =>
      ThemeData(useMaterial3: true, fontFamily: 'SourceSans3');
}
