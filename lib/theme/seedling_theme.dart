import 'package:flutter/material.dart';

import 'seedling_palette.dart';

/// The Seedling notebook theme: warm paper surfaces, ink text, serif headers
/// (SourceSerif4) over a legible sans for user content (SourceSans3).
///
/// Every text style names its `fontFamily` explicitly — the golden renderer
/// draws tofu boxes for styles that only inherit one. Only the SemiBold cut of
/// SourceSerif4 is bundled, so serif styles are all `FontWeight.w600`;
/// anything else gets fake-bolded.
class SeedlingTheme {
  const SeedlingTheme._();

  static const String _serifFamily = 'SourceSerif4';
  static const String _sansFamily = 'SourceSans3';

  /// Cards, buttons and inputs share this corner radius.
  static const double _radius = 12;

  static ThemeData light() {
    final textTheme = _textTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: SeedlingPalette.paper,
      // Catches text built outside the textTheme: an unnamed family renders as
      // tofu boxes in golden tests.
      fontFamily: _sansFamily,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: SeedlingPalette.paper,
        surfaceTintColor: SeedlingPalette.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: SeedlingPalette.paperLine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SeedlingPalette.greenDeep,
          foregroundColor: SeedlingPalette.paper,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SeedlingPalette.greenDeep,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: textTheme.bodyMedium?.copyWith(color: SeedlingPalette.gray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: SeedlingPalette.grayLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: SeedlingPalette.grayLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: SeedlingPalette.greenDeep),
        ),
      ),
    );
  }

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: SeedlingPalette.greenDeep,
    onPrimary: SeedlingPalette.paper,
    primaryContainer: SeedlingPalette.paperLine,
    onPrimaryContainer: SeedlingPalette.ink,
    secondary: SeedlingPalette.azure,
    onSecondary: SeedlingPalette.paper,
    secondaryContainer: SeedlingPalette.paperLine,
    onSecondaryContainer: SeedlingPalette.ink,
    tertiary: SeedlingPalette.orange,
    onTertiary: SeedlingPalette.ink,
    tertiaryContainer: SeedlingPalette.paperLine,
    onTertiaryContainer: SeedlingPalette.ink,
    error: SeedlingPalette.red,
    onError: SeedlingPalette.paper,
    errorContainer: SeedlingPalette.paperLine,
    onErrorContainer: SeedlingPalette.ink,
    surface: SeedlingPalette.paper,
    onSurface: SeedlingPalette.ink,
    surfaceDim: SeedlingPalette.paperLine,
    surfaceBright: SeedlingPalette.paper,
    surfaceContainerLowest: SeedlingPalette.paper,
    surfaceContainerLow: SeedlingPalette.paper,
    surfaceContainer: SeedlingPalette.paper,
    surfaceContainerHigh: SeedlingPalette.paper,
    surfaceContainerHighest: SeedlingPalette.paperLine,
    onSurfaceVariant: SeedlingPalette.grayDark,
    outline: SeedlingPalette.grayLight,
    outlineVariant: SeedlingPalette.paperLine,
    shadow: SeedlingPalette.ink,
    scrim: SeedlingPalette.ink,
    inverseSurface: SeedlingPalette.ink,
    onInverseSurface: SeedlingPalette.paper,
    inversePrimary: SeedlingPalette.green,
    surfaceTint: SeedlingPalette.paper,
  );

  /// Serif for the notebook headers, sans for everything the user reads or
  /// types.
  static TextTheme _textTheme() => TextTheme(
        displayLarge: _serif(44),
        displayMedium: _serif(36),
        displaySmall: _serif(30),
        headlineLarge: _serif(28),
        headlineMedium: _serif(24),
        headlineSmall: _serif(20),
        titleLarge: _serif(18),
        titleMedium: _sans(16, weight: FontWeight.w600),
        titleSmall: _sans(14, weight: FontWeight.w600),
        bodyLarge: _sans(16),
        bodyMedium: _sans(14),
        bodySmall: _sans(12, color: SeedlingPalette.grayDark),
        labelLarge: _sans(14, weight: FontWeight.w500),
        labelMedium:
            _sans(12, weight: FontWeight.w500, color: SeedlingPalette.grayDark),
        labelSmall:
            _sans(11, weight: FontWeight.w500, color: SeedlingPalette.grayDark),
      );

  /// Only the SemiBold cut of SourceSerif4 is bundled — w600 is not a style
  /// choice here, it is the only weight that renders without fake-bolding.
  static TextStyle _serif(double size) => TextStyle(
        fontFamily: _serifFamily,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1.2,
        color: SeedlingPalette.ink,
      );

  static TextStyle _sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = SeedlingPalette.ink,
  }) =>
      TextStyle(
        fontFamily: _sansFamily,
        fontWeight: weight,
        fontSize: size,
        height: 1.35,
        color: color,
      );
}
