import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/screens/settings_screen.dart';
import 'package:seedling/theme/seedling_theme.dart';

import '../util/golden/golden_utils.dart';

Widget _settings({
  bool eink = false,
  ValueChanged<bool>? onEinkChanged,
  VoidCallback? onOpenTags,
  VoidCallback? onOpenQuestions,
  VoidCallback? onOpenSomeday,
  VoidCallback? onSignOut,
}) =>
    SettingsView(
      einkMode: eink,
      onEinkChanged: onEinkChanged ?? (_) {},
      onOpenTags: onOpenTags ?? () {},
      onOpenQuestions: onOpenQuestions ?? () {},
      onOpenSomeday: onOpenSomeday ?? () {},
      onSignOut: onSignOut ?? () {},
      signedInAs: 'test@sdevaan.nl',
    );

void main() {
  goldenForSizes('settings', 'settings', [GoldenSize.phone, GoldenSize.mac],
      () => _settings());

  testWidgets('settings in e-ink mode', (tester) async {
    configureSize(tester, GoldenSize.eink);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SeedlingTheme.eink(),
      home: _settings(eink: true),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings_eink.png'));
  });

  testWidgets('toggling e-ink reports the new value', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(wrapApp(_settings(onEinkChanged: changes.add)));

    await tester.tap(find.byType(Switch));

    expect(changes, [true]);
  });

  testWidgets('the account block offers a way out', (tester) async {
    var signOuts = 0;
    await tester.pumpWidget(wrapApp(_settings(onSignOut: () => signOuts++)));

    expect(find.text('test@sdevaan.nl'), findsOneWidget);
    await tester.tap(find.text('Sign out'));

    expect(signOuts, 1);
  });

  testWidgets('tags are reachable from settings', (tester) async {
    var opens = 0;
    await tester.pumpWidget(wrapApp(_settings(onOpenTags: () => opens++)));

    await tester.tap(find.text('Tags'));

    expect(opens, 1);
  });

  testWidgets('e-ink mode swaps the page to white and the greys to ink',
      (tester) async {
    const paper = SeedlingColors.paperMode;
    const eink = SeedlingColors.einkMode;

    expect(eink.paper, const Color(0xFFFFFFFF));
    expect(eink.muted, eink.ink, reason: 'no mid-grey text on e-ink');
    expect(paper.muted, isNot(paper.ink));
    expect(eink.eink, isTrue);
    expect(paper.eink, isFalse);
  });
}
