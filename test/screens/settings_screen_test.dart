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
      onOpenGoals: () {},
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

  testWidgets('the vault block is hidden where there is nowhere to write it',
      (tester) async {
    await tester.pumpWidget(wrapApp(_settings()));

    expect(find.text('Markdown vault'), findsNothing);
  });

  testWidgets('exporting the vault reports back', (tester) async {
    var exports = 0;
    await tester.pumpWidget(wrapApp(SettingsView(
      einkMode: false,
      onEinkChanged: (_) {},
      onOpenTags: () {},
      onOpenQuestions: () {},
      onOpenSomeday: () {},
      onOpenGoals: () {},
      onSignOut: () {},
      onExportVault: () => exports++,
      vaultPath: '/Users/bassiuz/Seedling Vault',
      exportStatus: 'Wrote 42 files',
    )));

    expect(find.text('/Users/bassiuz/Seedling Vault'), findsOneWidget);
    expect(find.text('Wrote 42 files'), findsOneWidget);

    final exportTile =
        find.widgetWithText(ListTile, 'Export everything now');
    await tester.ensureVisible(exportTile);
    await tester.pump();
    await tester.tap(exportTile, warnIfMissed: false);

    expect(exports, 1);
  });

  testWidgets('automatic mirroring can be turned off', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(wrapApp(SettingsView(
      einkMode: false,
      onEinkChanged: (_) {},
      onOpenTags: () {},
      onOpenQuestions: () {},
      onOpenSomeday: () {},
      onOpenGoals: () {},
      onSignOut: () {},
      onExportVault: () {},
      vaultPath: '/tmp/vault',
      mirroring: true,
      onMirroringChanged: changes.add,
    )));

    await tester.ensureVisible(find.text('Keep it up to date automatically'));
    await tester.tap(find.text('Keep it up to date automatically'));
    await tester.pump();

    expect(changes, [false]);
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
