import 'package:flutter/material.dart';

import 'seedling_palette.dart';

/// The surface and text colours a screen draws with. Widgets read these rather
/// than the palette constants so that e-ink mode can swap the whole set at
/// once; tag accents still come straight from [SeedlingPalette], because those
/// are already chosen to be displayable on the BigMe panel.
@immutable
class SeedlingColors extends ThemeExtension<SeedlingColors> {
  const SeedlingColors({
    required this.paper,
    required this.rule,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.eink,
  });

  /// Page background.
  final Color paper;

  /// Ruled lines, dividers, hairlines.
  final Color rule;

  /// Body text and outlines.
  final Color ink;

  /// Secondary text: times, origin notes, section hints.
  final Color muted;

  /// Placeholder text and disabled outlines.
  final Color faint;

  /// True in high-contrast e-ink mode. Widgets use it to drop shadows and
  /// animation, not to pick colours — the colours above already changed.
  final bool eink;

  static SeedlingColors of(BuildContext context) =>
      Theme.of(context).extension<SeedlingColors>()!;

  static const paperMode = SeedlingColors(
    paper: SeedlingPalette.paper,
    rule: SeedlingPalette.paperLine,
    ink: SeedlingPalette.ink,
    muted: SeedlingPalette.grayDark,
    faint: SeedlingPalette.grayLight,
    eink: false,
  );

  /// Pure white and pure black, with mid greys pulled towards ink: a colour
  /// e-ink panel renders subtle greys as mush.
  static const einkMode = SeedlingColors(
    paper: Color(0xFFFFFFFF),
    rule: SeedlingPalette.gray,
    ink: SeedlingPalette.ink,
    muted: SeedlingPalette.ink,
    faint: SeedlingPalette.gray,
    eink: true,
  );

  @override
  SeedlingColors copyWith({
    Color? paper,
    Color? rule,
    Color? ink,
    Color? muted,
    Color? faint,
    bool? eink,
  }) =>
      SeedlingColors(
        paper: paper ?? this.paper,
        rule: rule ?? this.rule,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        faint: faint ?? this.faint,
        eink: eink ?? this.eink,
      );

  @override
  SeedlingColors lerp(SeedlingColors? other, double t) {
    if (other == null) return this;
    return SeedlingColors(
      paper: Color.lerp(paper, other.paper, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      eink: t < 0.5 ? eink : other.eink,
    );
  }
}

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

  static ThemeData light() => _build(SeedlingColors.paperMode);

  /// High-contrast mode for the BigMe: white page, ink text, accents kept.
  static ThemeData eink() => _build(SeedlingColors.einkMode);

  static ThemeData of({required bool eink}) =>
      eink ? SeedlingTheme.eink() : SeedlingTheme.light();

  // ponytail: no component themes (card/button/input) until a screen actually
  // renders one — untested theme config is config that silently rots. Add each
  // one alongside the widget that needs it, and golden-test them together.
  static ThemeData _build(SeedlingColors colors) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _colorScheme.copyWith(
          surface: colors.paper,
          onSurface: colors.ink,
          onSurfaceVariant: colors.muted,
          outline: colors.faint,
          outlineVariant: colors.rule,
        ),
        scaffoldBackgroundColor: colors.paper,
        // Catches text built outside the textTheme: an unnamed family renders
        // as tofu boxes in golden tests.
        fontFamily: _sansFamily,
        textTheme: _textTheme(colors),
        extensions: [colors],
      );

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
  static TextTheme _textTheme(SeedlingColors c) => TextTheme(
        displayLarge: _serif(44, c),
        displayMedium: _serif(36, c),
        displaySmall: _serif(30, c),
        headlineLarge: _serif(28, c),
        headlineMedium: _serif(24, c),
        headlineSmall: _serif(20, c),
        titleLarge: _serif(18, c),
        titleMedium: _sans(16, c, weight: FontWeight.w600),
        titleSmall: _sans(14, c, weight: FontWeight.w600),
        bodyLarge: _sans(16, c),
        bodyMedium: _sans(14, c),
        bodySmall: _sans(12, c, color: c.muted),
        labelLarge: _sans(14, c, weight: FontWeight.w500),
        labelMedium: _sans(12, c, weight: FontWeight.w500, color: c.muted),
        labelSmall: _sans(11, c, weight: FontWeight.w500, color: c.muted),
      );

  /// Only the SemiBold cut of SourceSerif4 is bundled — w600 is not a style
  /// choice here, it is the only weight that renders without fake-bolding.
  /// Emoji have no glyphs in either bundled family, so without this fallback
  /// every emoji renders as a tofu box — in goldens and on device alike.
  static const List<String> _emojiFallback = ['NotoColorEmoji'];

  static TextStyle _serif(double size, SeedlingColors c) => TextStyle(
        fontFamily: _serifFamily,
        fontFamilyFallback: _emojiFallback,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1.2,
        color: c.ink,
      );

  static TextStyle _sans(
    double size,
    SeedlingColors c, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: _sansFamily,
        fontFamilyFallback: _emojiFallback,
        fontWeight: weight,
        fontSize: size,
        height: 1.35,
        color: color ?? c.ink,
      );
}
