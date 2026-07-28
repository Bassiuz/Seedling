import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/screens/settings_screen.dart';
import 'package:seedling/screens/tags_screen.dart';
import 'package:seedling/widgets/back_line.dart';

import '../util/golden/golden_utils.dart';

/// A pushed screen with something underneath it, the way the app arranges them.
Widget _pushed(Widget screen) => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

Widget _settings() => SettingsView(
      einkMode: false,
      onEinkChanged: (_) {},
      onOpenTags: () {},
      onOpenQuestions: () {},
      onOpenSomeday: () {},
      onSignOut: () {},
    );

void main() {
  testWidgets('settings can be left again', (tester) async {
    await tester.pumpWidget(wrapApp(_pushed(_settings())));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing,
        reason: 'the back arrow popped the route');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('tags can be left again', (tester) async {
    await tester.pumpWidget(wrapApp(
      _pushed(TagsView(tags: const [], onEdit: (_) {}, onAdd: () {})),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BackLine), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}
