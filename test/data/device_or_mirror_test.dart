import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/calendar_source.dart';
import 'package:seedling/models/calendar_event.dart';

const _from = '2026-07-01';
const _to = '2026-08-31';

CalendarEvent _event(String title) => CalendarEvent(
    id: title, title: title, dayKey: '2026-07-28', allDay: false, time: '09:00');

/// A source that throws, like a device with no calendar plugin.
class _Broken implements CalendarSource {
  @override
  Future<bool> get available async => false;

  @override
  bool get worthSharing => true;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) =>
      throw StateError('no calendar here');
}

void main() {
  test('this device wins when it has appointments of its own', () async {
    final source = DeviceOrMirror(
      FakeCalendar([_event('Mine')]),
      FakeCalendar([_event('Shared')]),
    );

    final events = await source.eventsBetween(_from, _to);

    expect(events.map((e) => e.title), ['Mine']);
    expect(source.worthSharing, isTrue);
  });

  test('an empty calendar falls through to what was shared', () async {
    // The BigMe's whole situation: it can read a calendar, there is just no
    // account in it, and nothing read is not the same as a quiet two months.
    final source = DeviceOrMirror(
      const FakeCalendar([]),
      FakeCalendar([_event('Shared')]),
    );

    expect((await source.eventsBetween(_from, _to)).map((e) => e.title),
        ['Shared']);
  });

  test('a device that fell back has nothing worth sharing back', () async {
    final source = DeviceOrMirror(
      const FakeCalendar([]),
      FakeCalendar([_event('Shared')]),
    );
    await source.eventsBetween(_from, _to);

    expect(source.worthSharing, isFalse,
        reason: 'republishing a mirror over itself helps nobody');
  });

  test('a calendar that throws falls back rather than failing', () async {
    final source = DeviceOrMirror(_Broken(), FakeCalendar([_event('Shared')]));

    expect((await source.eventsBetween(_from, _to)).map((e) => e.title),
        ['Shared']);
  });

  test('a mirror never claims to be worth sharing', () {
    expect(MirrorCalendar((_, _) async => const []).worthSharing, isFalse);
  });
}
