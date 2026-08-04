import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/screens/day_page.dart';

import '../util/golden/golden_utils.dart';

void main() {
  // An app left open overnight used to insist it was still yesterday, and
  // everything downstream believed it: which tasks rolled over, which window
  // of calendar was published, what the widget said.
  testWidgets('the day page notices midnight while it is open', (tester) async {
    configureSize(tester, GoldenSize.mac);
    var now = DateTime(2026, 8, 3, 23, 59);
    nowFor = () => now;
    addTearDown(() => nowFor = DateTime.now);

    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Monday work', date: '2026-08-03');
    await repo.addTask('Tuesday work', date: '2026-08-04');

    await tester.pumpWidget(wrapApp(DayPage(
      repo: repo,
      calendar: const NoCalendar(),
    )));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Monday'), findsOneWidget);

    // Midnight passes. The clock tick is what asks whether the date moved.
    now = DateTime(2026, 8, 4, 0, 1);
    await tester.pump(const Duration(minutes: 1));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Tuesday'), findsOneWidget,
        reason: 'today moved on, and the page with it');
    expect(find.text('Monday'), findsNothing);
  });
}
