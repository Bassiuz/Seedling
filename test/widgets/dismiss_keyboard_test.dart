import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/widgets/dismiss_keyboard.dart';

import '../util/golden/golden_utils.dart';

Widget _page({VoidCallback? onButton}) => DismissKeyboard(
      child: Scaffold(
        body: Column(
          children: [
            const TextField(
              decoration: InputDecoration(hintText: 'Type here'),
            ),
            const Text('Just some text'),
            TextButton(onPressed: onButton ?? () {}, child: const Text('Tap me')),
          ],
        ),
      ),
    );

void main() {
  testWidgets('tapping plain text puts the keyboard away', (tester) async {
    await tester.pumpWidget(wrapApp(_page()));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Just some text'));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('buttons still get their taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrapApp(_page(onButton: () => taps++)));

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('tapping the field itself keeps the keyboard up',
      (tester) async {
    await tester.pumpWidget(wrapApp(_page()));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isTrue);
  });
}
