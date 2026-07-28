import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/logic/day_key.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/screens/day_page.dart';

import '../util/golden/golden_utils.dart';

/// Long-pressing an existing task must offer everything the add line does —
/// a tag and a time are as often decided afterwards as while typing.
void main() {
  testWidgets('an existing task can be given a tag it did not have',
      (tester) async {
    configureSize(tester, GoldenSize.phone);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.upsertTag(const Tag(
        id: 'moxify',
        name: 'Moxify',
        colorIndex: 6,
        iconIndex: 1,
        sortOrder: 0));
    await repo.addTask('Edit Cozy Zone', date: todayKey());

    await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Edit Cozy Zone'));
    await tester.pumpAndSettle();
    expect(find.text('Set a tag…'), findsOneWidget);

    await tester.tap(find.text('Set a tag…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moxify'));
    await tester.pumpAndSettle();

    expect((await repo.watchTasks().first).single.tagId, 'moxify');
  });

  testWidgets('the menu offers to remove a time only when there is one',
      (tester) async {
    configureSize(tester, GoldenSize.phone);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Vet appointment', date: todayKey(), time: '09:00');

    await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Vet appointment'));
    await tester.pumpAndSettle();

    expect(find.text('Change time'), findsOneWidget);
    expect(find.text('Remove the time'), findsOneWidget);
    expect(find.text('Set a time…'), findsNothing);
  });

  testWidgets('removing the time moves the task out of the timed list',
      (tester) async {
    configureSize(tester, GoldenSize.phone);
    final repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas');
    await repo.addTask('Vet appointment', date: todayKey(), time: '09:00');

    await tester.pumpWidget(wrapApp(DayPage(repo: repo)));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Vet appointment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove the time'));
    await tester.pumpAndSettle();

    expect((await repo.watchTasks().first).single.time, isNull);
  });
}
