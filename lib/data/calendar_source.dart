import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';

import '../logic/day_key.dart';
import '../logic/event_time.dart';
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

  /// Whether what was last returned came off this device, and so is worth
  /// sharing with the others. False once a source has read a mirror instead —
  /// republishing a mirror back over itself helps nobody.
  bool get worthSharing => true;
}

/// Always empty — used where no calendar is reachable, and in tests.
class NoCalendar implements CalendarSource {
  const NoCalendar();

  @override
  bool get worthSharing => false;

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
  bool get worthSharing => true;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async =>
      events
          .where((e) =>
              e.dayKey.compareTo(from) >= 0 && e.dayKey.compareTo(to) <= 0)
          .toList();

  @override
  Future<bool> get available async => true;
}

/// The real thing, via EventKit on iOS and the calendar provider on Android.
///
/// `device_calendar` ships implementations for those two platforms only — there
/// is no macOS one, so on the Mac the method channel does not exist. Anything
/// else reads the mirror those devices publish instead.
class DeviceCalendar implements CalendarSource {
  DeviceCalendar([DeviceCalendarPlugin? plugin])
      : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  @override
  bool get worthSharing => true;

  /// Where a calendar can actually be read from the device.
  static bool get supported => Platform.isIOS || Platform.isAndroid;

  @override
  Future<bool> get available async {
    if (!supported) return false;
    try {
      final granted = await _plugin.hasPermissions();
      if (granted.isSuccess && granted.data == true) return true;
      final asked = await _plugin.requestPermissions();
      return asked.isSuccess && asked.data == true;
    } on MissingPluginException {
      // No implementation on this platform; not an error worth surfacing.
      return false;
    }
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
        final when = localEventTime(start, allDay: allDay);
        found.add(CalendarEvent(
          id: event.eventId ?? '${calendar.id}-${start.millisecondsSinceEpoch}',
          title: event.title ?? '(no title)',
          dayKey: when.dayKey,
          allDay: allDay,
          time: when.time,
          calendarName: calendar.name,
          // Repeating events share this, so hiding one hides the series.
          recurringId: event.recurrenceRule == null ? null : event.eventId,
        ));
      }
    }
    return found;
  }
}

/// Reads the events your phone published, for the machines that cannot see a
/// calendar themselves — the Mac and the BigMe.
///
/// One-way: this never writes, so a device without calendar access can never
/// stale out what the phone knows.
class MirrorCalendar implements CalendarSource {
  const MirrorCalendar(this.read);

  @override
  bool get worthSharing => false;

  /// Usually `SeedlingRepo.readCalendarMirror`.
  final Future<List<CalendarEvent>> Function(String from, String to) read;

  @override
  Future<bool> get available async => true;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) =>
      read(from, to);
}

/// This device's own calendar, falling back to what another device shared.
///
/// The BigMe runs Android, so it *can* read a calendar — it just has no
/// account in it, and an empty read is indistinguishable from a quiet day.
/// Rather than making that a setting you have to know to change, an empty
/// read falls through to the mirror. A device with its own appointments never
/// reaches the fallback, so nothing is lost by trying.
class DeviceOrMirror implements CalendarSource {
  DeviceOrMirror(this.device, this.mirror);

  final CalendarSource device;
  final CalendarSource mirror;

  bool _readOwn = false;

  @override
  Future<bool> get available async => true;

  @override
  bool get worthSharing => _readOwn;

  @override
  Future<List<CalendarEvent>> eventsBetween(String from, String to) async {
    _readOwn = false;
    try {
      final own = await device.eventsBetween(from, to);
      if (own.isNotEmpty) {
        _readOwn = true;
        return own;
      }
    } catch (_) {
      // No calendar here, or permission refused. The mirror is the answer to
      // both.
    }
    return mirror.eventsBetween(from, to);
  }
}
