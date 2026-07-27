import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/theme/seedling_palette.dart';
import 'package:seedling/theme/seedling_theme.dart';

import '../util/golden/golden_utils.dart';

/// Every token in the palette, in design-doc order, for the swatch grid.
const _swatches = <(String, Color)>[
  ('ink', SeedlingPalette.ink),
  ('grayDark', SeedlingPalette.grayDark),
  ('gray', SeedlingPalette.gray),
  ('grayLight', SeedlingPalette.grayLight),
  ('red', SeedlingPalette.red),
  ('green', SeedlingPalette.green),
  ('blue', SeedlingPalette.blue),
  ('cyan', SeedlingPalette.cyan),
  ('orange', SeedlingPalette.orange),
  ('yellow', SeedlingPalette.yellow),
  ('greenDeep', SeedlingPalette.greenDeep),
  ('purple', SeedlingPalette.purple),
  ('azure', SeedlingPalette.azure),
  ('crimson', SeedlingPalette.crimson),
  ('magenta', SeedlingPalette.magenta),
  ('paper', SeedlingPalette.paper),
  ('paperLine', SeedlingPalette.paperLine),
];

const _neutrals = <Color>[
  SeedlingPalette.ink,
  SeedlingPalette.grayDark,
  SeedlingPalette.gray,
  SeedlingPalette.grayLight,
  SeedlingPalette.paper,
  SeedlingPalette.paperLine,
];

void main() {
  test('tagColors are the 11 accents, no neutrals and no duplicates', () {
    expect(SeedlingPalette.tagColors, hasLength(11));
    expect(SeedlingPalette.tagColors.toSet(), hasLength(11));
    for (final neutral in _neutrals) {
      expect(SeedlingPalette.tagColors, isNot(contains(neutral)));
    }
  });

  test('every text style names a bundled font family and a color', () {
    // The flutter_tester engine renders tofu unless a style names a family,
    // and only SemiBold SourceSerif4 is bundled, so serif must be w600.
    for (final entry in _textStyles(SeedlingTheme.light().textTheme).entries) {
      final style = entry.value;
      expect(style, isNotNull, reason: entry.key);
      expect(style!.fontFamily, anyOf('SourceSans3', 'SourceSerif4'),
          reason: entry.key);
      expect(style.color, isNotNull, reason: entry.key);
      if (style.fontFamily == 'SourceSerif4') {
        expect(style.fontWeight, FontWeight.w600, reason: entry.key);
      }
    }
  });

  test('no Material purple survives in the color scheme', () {
    for (final entry in _schemeColors(SeedlingTheme.light().colorScheme)
        .entries) {
      final hsl = HSLColor.fromColor(entry.value);
      final isPurple =
          hsl.saturation > 0.1 && hsl.hue >= 250 && hsl.hue <= 330;
      expect(isPurple, isFalse,
          reason: '${entry.key} is purple (hue ${hsl.hue.round()})');
    }
  });

  goldenForSizes(
    'theme gallery',
    'theme_gallery',
    [GoldenSize.phone],
    () => const _ThemeGallery(),
  );
}

Map<String, TextStyle?> _textStyles(TextTheme t) => {
      'displayLarge': t.displayLarge,
      'displayMedium': t.displayMedium,
      'displaySmall': t.displaySmall,
      'headlineLarge': t.headlineLarge,
      'headlineMedium': t.headlineMedium,
      'headlineSmall': t.headlineSmall,
      'titleLarge': t.titleLarge,
      'titleMedium': t.titleMedium,
      'titleSmall': t.titleSmall,
      'bodyLarge': t.bodyLarge,
      'bodyMedium': t.bodyMedium,
      'bodySmall': t.bodySmall,
      'labelLarge': t.labelLarge,
      'labelMedium': t.labelMedium,
      'labelSmall': t.labelSmall,
    };

Map<String, Color> _schemeColors(ColorScheme s) => {
      'primary': s.primary,
      'onPrimary': s.onPrimary,
      'primaryContainer': s.primaryContainer,
      'onPrimaryContainer': s.onPrimaryContainer,
      'secondary': s.secondary,
      'onSecondary': s.onSecondary,
      'secondaryContainer': s.secondaryContainer,
      'onSecondaryContainer': s.onSecondaryContainer,
      'tertiary': s.tertiary,
      'onTertiary': s.onTertiary,
      'tertiaryContainer': s.tertiaryContainer,
      'onTertiaryContainer': s.onTertiaryContainer,
      'error': s.error,
      'onError': s.onError,
      'errorContainer': s.errorContainer,
      'onErrorContainer': s.onErrorContainer,
      'surface': s.surface,
      'onSurface': s.onSurface,
      'surfaceDim': s.surfaceDim,
      'surfaceBright': s.surfaceBright,
      'surfaceContainerLowest': s.surfaceContainerLowest,
      'surfaceContainerLow': s.surfaceContainerLow,
      'surfaceContainer': s.surfaceContainer,
      'surfaceContainerHigh': s.surfaceContainerHigh,
      'surfaceContainerHighest': s.surfaceContainerHighest,
      'onSurfaceVariant': s.onSurfaceVariant,
      'outline': s.outline,
      'outlineVariant': s.outlineVariant,
      'shadow': s.shadow,
      'scrim': s.scrim,
      'inverseSurface': s.inverseSurface,
      'onInverseSurface': s.onInverseSurface,
      'inversePrimary': s.inversePrimary,
      'surfaceTint': s.surfaceTint,
    };

/// Visual reference for the design system: every palette token as a swatch,
/// plus one line of each key text style so serif headers and sans body are
/// obviously different.
class _ThemeGallery extends StatelessWidget {
  const _ThemeGallery();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Palette', style: text.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final (name, color) in _swatches)
                  _Swatch(
                    name: name,
                    color: color,
                    isTagColor: SeedlingPalette.tagColors.contains(color),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('• marks the ${SeedlingPalette.tagColors.length} tag colors',
                style: text.labelSmall),
            const SizedBox(height: 20),
            Text('Type', style: text.titleLarge),
            const SizedBox(height: 8),
            _Sample('Display', text.displayMedium),
            _Sample('Headline', text.headlineMedium),
            _Sample('Title', text.titleLarge),
            _Sample('Body', text.bodyMedium),
            _Sample('Label', text.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.color,
    required this.isTagColor,
  });

  final String name;
  final Color color;
  final bool isTagColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SeedlingPalette.grayLight),
                ),
              ),
              if (isTagColor)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SeedlingPalette.paper,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Sample extends StatelessWidget {
  const _Sample(this.name, this.style);

  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$name · ${style?.fontFamily}',
              style: Theme.of(context).textTheme.labelSmall),
          Text('Seedling notebook', style: style),
        ],
      ),
    );
  }
}
