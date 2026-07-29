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
            title: 'Dentist appointment',
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
    expect(read.single.title, 'Dentist appointment');
  });

  test('nothing published means nothing to read', () async {
    expect(await repo.readCalendarMirror('2026-07-01', '2026-08-31'), isEmpty);
  });

  test('what the phone publishes is what another device reads', () async {
    await repo.publishCalendarMirror(
      [_event('Dentist appointment', '2026-07-28', time: '09:00')],
      from: '2026-07-01',
      to: '2026-08-31',
    );

    final read = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(read, hasLength(1));
    expect(read.single.title, 'Dentist appointment');
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

  test('every occurrence of a repeating event survives the mirror', () async {
    // EventKit gives each occurrence the same identifier, so keying on it
    // alone kept one Tuesday and dropped the rest — which on the Mac looked
    // like the meeting not existing at all.
    const id = 'weekly-standup';
    await repo.publishCalendarMirror(
      [
        for (final day in ['2026-07-28', '2026-08-04', '2026-08-11'])
          CalendarEvent(
              id: id,
              title: 'Standup',
              dayKey: day,
              allDay: false,
              time: '09:30',
              recurringId: id),
      ],
      from: '2026-07-01',
      to: '2026-08-31',
    );

    final mirrored = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(mirrored.map((e) => e.dayKey).toSet(),
        {'2026-07-28', '2026-08-04', '2026-08-11'});
    expect(mirrored.every((e) => e.id == id), isTrue,
        reason: 'the real id still travels in the body');
  });

  test('two occurrences on one day at different times both survive', () async {
    const id = 'daily-checkin';
    await repo.publishCalendarMirror(
      [
        for (final time in ['09:30', '16:00'])
          CalendarEvent(
              id: id,
              title: 'Check-in',
              dayKey: '2026-07-28',
              allDay: false,
              time: time,
              recurringId: id),
      ],
      from: '2026-07-01',
      to: '2026-08-31',
    );

    final mirrored = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(mirrored.map((e) => e.time).toSet(), {'09:30', '16:00'});
  });

  test('a calendar too big for one Firestore batch is published whole',
      () async {
    // The limit is 500 operations; two months of a busy calendar is past it,
    // and an over-long batch used to fail the lot rather than write some.
    final many = [
      for (var i = 0; i < 600; i++)
        CalendarEvent(
            id: 'event-$i',
            title: 'Event $i',
            dayKey: '2026-07-28',
            allDay: false,
            time: '09:00'),
    ];

    await repo.publishCalendarMirror(many,
        from: '2026-07-01', to: '2026-08-31');

    expect(await repo.readCalendarMirror('2026-07-01', '2026-08-31'),
        hasLength(600));
  });

  test('republishing over a big window still clears what went before',
      () async {
    final many = [
      for (var i = 0; i < 600; i++)
        CalendarEvent(
            id: 'event-$i',
            title: 'Event $i',
            dayKey: '2026-07-28',
            allDay: false,
            time: '09:00'),
    ];
    await repo.publishCalendarMirror(many,
        from: '2026-07-01', to: '2026-08-31');

    await repo.publishCalendarMirror([_event('Only this', '2026-07-28')],
        from: '2026-07-01', to: '2026-08-31');

    final mirrored = await repo.readCalendarMirror('2026-07-01', '2026-08-31');
    expect(mirrored.map((e) => e.title), ['Only this']);
  });

  test('nothing has been shared until a device shares something', () async {
    expect(await repo.watchCalendarShare().first, isNull);
  });

  test('a publish records how much arrived', () async {
    await repo.publishCalendarMirror(
      [_event('Vet', '2026-07-28'), _event('Standup', '2026-07-29')],
      from: '2026-07-01',
      to: '2026-08-31',
    );

    final share = await repo.watchCalendarShare().first;
    expect(share?.count, 2);
    expect(share?.at, isNotNull);
  });
}
