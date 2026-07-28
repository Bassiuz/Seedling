import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';

void main() {
  late SeedlingRepo repo;

  setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

  test('a day with nothing ticked yields an empty set', () async {
    expect(await repo.watchDoneEvents('2026-07-28').first, isEmpty);
  });

  test('ticking an event off records it and unticking clears it', () async {
    await repo.setEventDone('2026-07-28', 'vet', true);
    expect(await repo.watchDoneEvents('2026-07-28').first, {'vet'});

    await repo.setEventDone('2026-07-28', 'vet', false);
    expect(await repo.watchDoneEvents('2026-07-28').first, isEmpty);
  });

  test('a repeating event done today is still waiting tomorrow', () async {
    await repo.setEventDone('2026-07-28', 'standup', true);

    expect(await repo.watchDoneEvents('2026-07-28').first, {'standup'});
    expect(await repo.watchDoneEvents('2026-07-29').first, isEmpty);
  });

  test('ticking one does not disturb the note on the same day', () async {
    await repo.saveNote('2026-07-28', 'Long day.');
    await repo.setEventDone('2026-07-28', 'vet', true);

    expect(await repo.watchNote('2026-07-28').first, 'Long day.');
    expect(await repo.watchDoneEvents('2026-07-28').first, {'vet'});
  });
}
