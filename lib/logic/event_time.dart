import 'day_key.dart';

/// When a calendar event lands, in the wall-clock time of wherever you are.
///
/// The calendar plugin hands back a `TZDateTime`, and calling `.toLocal()` on
/// one is a no-op — its `isUtc` flag is already false even though the digits
/// are UTC, so a 13:30 appointment renders as 11:30 in summer. Going through
/// the epoch sidesteps the whole question: it is the absolute instant, and
/// `DateTime.fromMillisecondsSinceEpoch` always returns it in system-local
/// time.
({String dayKey, String? time}) localEventTime(
  DateTime start, {
  required bool allDay,
}) {
  // All-day events go through the same conversion. EventKit stores them at
  // *local* midnight, which as an absolute instant is the evening before in
  // UTC — reading the raw components put a Wednesday event on Tuesday. They
  // just carry no clock time.
  final local = DateTime.fromMillisecondsSinceEpoch(start.millisecondsSinceEpoch);
  return (dayKey: dayKeyOf(local), time: allDay ? null : clockOf(local));
}

/// `HH:mm`, the format times are stored and shown in.
String clockOf(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// True when [time] on [day] has already gone by. Only ever true for today —
/// a past day is history, not a to-do, and a future one has not arrived.
bool isOverdue({
  required String day,
  required String? time,
  required String today,
  required String now,
}) {
  if (time == null) return false;
  if (day != today) return false;
  return time.compareTo(now) < 0;
}
