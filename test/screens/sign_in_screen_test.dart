import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/screens/sign_in_screen.dart';

import '../util/golden/golden_utils.dart';

Widget _form({
  Future<void> Function(String, String)? onSubmit,
  String? error,
  bool busy = false,
}) =>
    Scaffold(
      body: SafeArea(
        child: SignInForm(
          onSubmit: onSubmit ?? (_, _) async {},
          error: error,
          busy: busy,
        ),
      ),
    );

void main() {
  goldenForSizes('sign in', 'sign_in', [GoldenSize.phone, GoldenSize.mac],
      () => _form());

  goldenForSizes('sign in with an error', 'sign_in_error', [GoldenSize.phone],
      () => _form(error: 'The password is invalid.'));

  testWidgets('hands over the trimmed email and the password', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(wrapApp(_form(
      onSubmit: (email, password) async => submitted.addAll([email, password]),
    )));

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), '  bas@example.com ');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'hunter2');
    await tester.tap(find.text('Sign in'));

    expect(submitted, ['bas@example.com', 'hunter2']);
  });

  testWidgets('cannot be submitted twice while it is working', (tester) async {
    var submits = 0;
    await tester.pumpWidget(wrapApp(_form(
      onSubmit: (_, _) async => submits++,
      busy: true,
    )));

    await tester.tap(find.text('One moment…'));

    expect(submits, 0);
  });
}
