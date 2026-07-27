import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/theme/seedling_theme.dart';

/// Canonical Seedling screen contexts (design doc: Responsive layouts).
enum GoldenSize {
  phone(Size(390, 844), 3),        // iPhone
  eink(Size(632, 840), 2),         // BigMe B7 portrait
  macNarrow(Size(500, 950), 2),    // half-height Mac window
  mac(Size(1440, 900), 2);         // Mac full screen

  const GoldenSize(this.logical, this.ratio);
  final Size logical;
  final double ratio;
}

void configureSize(WidgetTester tester, GoldenSize s) {
  tester.view.physicalSize = s.logical * s.ratio;
  tester.view.devicePixelRatio = s.ratio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrapApp(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SeedlingTheme.light(),
      home: home,
    );

/// One golden per size: `goldens/<base>_<size>.png`
void goldenForSizes(String name, String base, List<GoldenSize> sizes,
    Widget Function() build) {
  for (final s in sizes) {
    testWidgets('$name (${s.name})', (tester) async {
      configureSize(tester, s);
      await tester.pumpWidget(wrapApp(build()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/${base}_${s.name}.png'));
    });
  }
}
