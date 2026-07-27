import 'package:device_calendar/device_calendar.dart';

import '../logic/day_key.dart';
import '../models/calendar_event.dart';

/// Reads appointments from the device calendar.
///
/// Read-only on purpose: Seedling is a lens on your calendar, not a calendar
/// client. Behind an interface so day pages and their tests never touch a real
/// device.
abstract class CalendarSource {
  /// Events between [from] and [to] inclusive, as day keys.
  Future<List<CalendarEvent>> eventsBetween(String from, String to);

  /// Whether this platform can read a calendar at all. The BigMe cannot see
  /// iCloud, so it falls back to whatever the Apple devices mirrored.
  Future<bool> get available;
}

/// Always empty — used where no calendar is reachable, and in tests.
class NoCalendar implements CalendarSource {
  const NoCalendar();

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async =>
      const [];

  @override
  Future<bool> get available async => false;
}

/// Fixed events, for tests and goldens.
class FakeCalendar implements CalendarSource {
  const FakeCalendar(this.events);

  final List<CalendarEvent> events;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async =>
      events
          .where((e) =>
              e.dayKey.compareTo(from) >= 0 && e.dayKey.compareTo(to) <= 0)
          .toList();

  @override
  Future<bool> get available async => true;
}

/// The real thing, via EventKit on Apple platforms and the calendar provider
/// on Android.
class DeviceCalendar implements CalendarSource {
  DeviceCalendar([DeviceCalendarPlugin? plugin])
      : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  @override
  Future<bool> get available async {
    final granted = await _plugin.hasPermissions();
    if (granted.isSuccess && granted.data == true) return true;
    final asked = await _plugin.requestPermissions();
    return asked.isSuccess && asked.data == true;
  }

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async {
    if (!await available) return const [];

    final calendars = await _plugin.retrieveCalendars();
    final found = <CalendarEvent>[];

    for (final calendar in calendars.data ?? <Calendar>[]) {
      final id = calendar.id;
      if (id == null) continue;
      final result = await _plugin.retrieveEvents(
        id,
        RetrieveEventsParams(
          startDate: dateOfKey(from),
          // The end of the last day, not its midnight.
          endDate: dateOfKey(to).add(const Duration(days: 1)),
        ),
      );
      for (final event in result.data ?? <Event>[]) {
        final start = event.start;
        if (start == null) continue;
        final allDay = event.allDay ?? false;
        found.add(CalendarEvent(
          id: event.eventId ?? '${calendar.id}-${start.millisecondsSinceEpoch}',
          title: event.title ?? '(no title)',
          dayKey: dayKeyOf(start.toLocal()),
          allDay: allDay,
          time: allDay
              ? null
              : '${start.toLocal().hour.toString().padLeft(2, '0')}:'
                  '${start.toLocal().minute.toString().padLeft(2, '0')}',
          calendarName: calendar.name,
          // Repeating events share this, so hiding one hides the series.
          recurringId: event.recurrenceRule == null ? null : event.eventId,
        ));
      }
    }
    return found;
  }
}
