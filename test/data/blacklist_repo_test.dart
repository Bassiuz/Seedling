import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';

void main() {
  late SeedlingRepo repo;

  setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

  test('a day with nothing hidden yields an empty set', () async {
    expect(await repo.watchHiddenEvents().first, isEmpty);
  });

  test('hiding accumulates keys and unhiding removes just the one', () async {
    await repo.hideEvent('plants');
    expect(await repo.watchHiddenEvents().first, {'plants'});

    await repo.hideEvent('Bins out');
    expect(await repo.watchHiddenEvents().first, {'plants', 'Bins out'});

    await repo.unhideEvent('plants');
    expect(await repo.watchHiddenEvents().first, {'Bins out'});
  });

  test('hiding the same thing twice does not duplicate it', () async {
    await repo.hideEvent('plants');
    await repo.hideEvent('plants');

    expect(await repo.watchHiddenEvents().first, hasLength(1));
  });

  test('one user cannot see what another hid', () async {
    await repo.hideEvent('plants');

    final other = SeedlingRepo(FakeFirebaseFirestore(), 'someone-else');
    expect(await other.watchHiddenEvents().first, isEmpty);
  });
}
