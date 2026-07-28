/// One appointment read from the device calendar.
///
/// Seedling never writes to the calendar — it is a lens on it — so this carries
/// only what a day page needs to draw a row.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.dayKey,
    required this.allDay,
    this.time,
    this.calendarName,
    this.recurringId,
  });

  final String id;
  final String title;

  /// The day this event belongs on, as a `yyyy-MM-dd` key.
  final String dayKey;
  final bool allDay;

  /// `HH:mm`, null for an all-day event.
  final String? time;
  final String? calendarName;

  /// Shared by every occurrence of a repeating event, so hiding "who is on
  /// holiday" once hides it for good rather than one day at a time.
  final String? recurringId;

  /// What a hide rule matches on: the series if there is one, else the title.
  String get hideKey => recurringId ?? title;

  Map<String, dynamic> toMap() => {
        // Carried explicitly: in the calendar mirror the document id is an
        // encoding of this, not the id itself.
        'id': id,
        'title': title,
        'dayKey': dayKey,
        'allDay': allDay,
        'time': time,
        'calendarName': calendarName,
        'recurringId': recurringId,
      };

  /// [fallbackId] is used only when the stored document has no id of its own.
  factory CalendarEvent.fromMap(String fallbackId, Map<String, dynamic> map) =>
      CalendarEvent(
        id: map['id'] as String? ?? fallbackId,
        title: map['title'] as String? ?? '',
        dayKey: map['dayKey'] as String? ?? '',
        allDay: map['allDay'] as bool? ?? false,
        time: map['time'] as String?,
        calendarName: map['calendarName'] as String?,
        recurringId: map['recurringId'] as String?,
      );
}
