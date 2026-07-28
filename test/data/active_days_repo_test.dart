import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';

const _day = '2026-07-28';

void main() {
  late SeedlingRepo repo;

  setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

  test('a day you never opened is not marked', () async {
    expect(await repo.watchActiveDays().first, isEmpty);
  });

  test('a note counts', () async {
    await repo.saveNote(_day, 'Long day.');
    expect(await repo.watchActiveDays().first, {_day});
  });

  test('an answered question counts', () async {
    await repo.setAnswer(_day, 'walked', 'yes');
    expect(await repo.watchActiveDays().first, {_day});
  });

  test('a ticked appointment counts', () async {
    await repo.setEventDone(_day, 'vet', true);
    expect(await repo.watchActiveDays().first, {_day});
  });

  test('a note you deleted again does not count', () async {
    await repo.saveNote(_day, 'Long day.');
    await repo.saveNote(_day, '   ');
    expect(await repo.watchActiveDays().first, isEmpty);
  });

  test('unticking the only appointment leaves the day blank', () async {
    await repo.setEventDone(_day, 'vet', true);
    await repo.setEventDone(_day, 'vet', false);
    expect(await repo.watchActiveDays().first, isEmpty);
  });
}
