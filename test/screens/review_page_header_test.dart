import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/screens/week_review_screen.dart';

import '../util/golden/golden_utils.dart';

/// In the day pager the pinned header already names the week, so the page
/// itself must not say it twice.
void main() {
  testWidgets('a review in the pager leaves the title to the header',
      (tester) async {
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await tester.pumpWidget(wrapApp(Scaffold(
      body: WeekReviewScreen(
        repo: repo,
        weekKey: '2026-W31',
        showBack: false,
        showTitle: false,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Week review'), findsNothing);
    expect(find.text('2026-W31'), findsNothing);
    expect(find.text('Observations'), findsOneWidget);
  });
}
