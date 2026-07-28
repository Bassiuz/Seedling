import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';
import 'package:seedling/models/calendar_event.dart';

CalendarEvent _event(String title, String day, {String? time}) => CalendarEvent(
    id: '$title-$day', title: title, dayKey: day, allDay: false, time: time);

void main() {
  late SeedlingRepo repo;

  setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

  test('an EventKit id containing a slash round-trips', () async {
    // This exact shape crashed the app: Firestore read the slash as a path
    // separator and rejected the reference outright.
    const realId =
        '______NativeStorePersistentID_______:gregorian/2DFB19BE-B573-478D';
    await repo.publishCalendarMirror(
      [
        CalendarEvent(
            id: realId,
            title: 'Vet appointment',
            dayKey: '2026-07-28',
            allDay: false,
            time: '09:00'),
      ],
      from: '2026-07-01',
      to: '2026-08-31',
    );

    final read = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(read.single.id, realId,
        reason: 'the real id survives, so ticking it off still matches');
    expect(read.single.title, 'Vet appointment');
  });

  test('nothing published means nothing to read', () async {
    expect(await repo.readCalendarMirror('2026-07-01', '2026-08-31'), isEmpty);
  });

  test('what the phone publishes is what another device reads', () async {
    await repo.publishCalendarMirror(
      [_event('Vet appointment', '2026-07-28', time: '09:00')],
      from: '2026-07-01',
      to: '2026-08-31',
    );

    final read = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(read, hasLength(1));
    expect(read.single.title, 'Vet appointment');
    expect(read.single.time, '09:00');
    expect(read.single.dayKey, '2026-07-28');
  });

  test('publishing again replaces the window rather than piling up', () async {
    await repo.publishCalendarMirror([_event('Old', '2026-07-28')],
        from: '2026-07-01', to: '2026-08-31');
    await repo.publishCalendarMirror([_event('New', '2026-07-28')],
        from: '2026-07-01', to: '2026-08-31');

    final read = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(read.map((e) => e.title).toList(), ['New'],
        reason: 'a cancelled appointment must not linger');
  });

  test('events outside the window are left alone', () async {
    await repo.publishCalendarMirror([_event('Far', '2026-12-25')],
        from: '2026-12-01', to: '2026-12-31');
    await repo.publishCalendarMirror([_event('Near', '2026-07-28')],
        from: '2026-07-01', to: '2026-08-31');

    expect((await repo.readCalendarMirror('2026-12-01', '2026-12-31')).single.title,
        'Far');
  });

  test('reading is bounded by the window asked for', () async {
    await repo.publishCalendarMirror(
      [_event('July', '2026-07-28'), _event('September', '2026-09-10')],
      from: '2026-07-01',
      to: '2026-09-30',
    );

    final july = await repo.readCalendarMirror('2026-07-01', '2026-07-31');
    expect(july.map((e) => e.title).toList(), ['July']);
  });

  test('one user cannot read another user\'s calendar', () async {
    await repo.publishCalendarMirror([_event('Private', '2026-07-28')],
        from: '2026-07-01', to: '2026-08-31');

    final other = SeedlingRepo(FakeFirebaseFirestore(), 'someone-else');
    expect(await other.readCalendarMirror('2026-07-01', '2026-08-31'), isEmpty);
  });
}
