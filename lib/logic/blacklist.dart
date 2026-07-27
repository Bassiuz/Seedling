import '../models/calendar_event.dart';

/// Which calendar events Seedling shows.
///
/// Plenty of what lives in a calendar is not work: who is on holiday, when the
/// bins go out, watering the plants. Those are already handled elsewhere, so
/// they are hidden here rather than deleted there.
///
/// A rule matches an event's [CalendarEvent.hideKey] — the repeating-series id
/// when there is one, so hiding a weekly event hides the whole series, and the
/// exact title otherwise.
bool isHidden(CalendarEvent event, Set<String> hiddenKeys) =>
    hiddenKeys.contains(event.hideKey);

/// The events to draw on a day.
///
/// With [reveal] on, hidden ones come back so a mistake can be undone — that is
/// the only way back from a hide rule you did not mean to add.
List<CalendarEvent> visibleEvents(
  List<CalendarEvent> events,
  Set<String> hiddenKeys, {
  bool reveal = false,
}) {
  final shown =
      reveal ? events : events.where((e) => !isHidden(e, hiddenKeys)).toList();
  return shown.toList()
    ..sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      final at = a.time ?? '';
      final bt = b.time ?? '';
      final byTime = at.compareTo(bt);
      return byTime != 0 ? byTime : a.title.compareTo(b.title);
    });
}
