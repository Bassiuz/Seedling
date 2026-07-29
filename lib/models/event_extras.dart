import '../logic/jira_ref.dart';

/// What Seedling knows about a calendar event beyond what the calendar says.
///
/// The calendar is only ever read, so a tag, a ticket or logged time has to
/// live here. Kept against the event's hide key — the repeating series where
/// there is one — because tagging "[Daily] standup" is a statement about the
/// series, not about Tuesday. Time is still logged per day inside it.
class EventExtras {
  const EventExtras({
    this.tagId,
    this.jira,
    this.title,
    this.minutes = const {},
  });

  final String? tagId;
  final JiraRef? jira;

  /// The appointment's own words, kept so anything reading this later — the
  /// Jira export, say — has something to show besides a hide key, which for a
  /// repeating event is an opaque id.
  final String? title;

  /// Minutes logged, by day key. ponytail: two occurrences of one series on
  /// the same day would share a total; split by event id if that ever happens.
  final Map<String, int> minutes;

  bool get isEmpty => tagId == null && jira == null && minutes.isEmpty;

  int minutesOn(String dayKey) => minutes[dayKey] ?? 0;

  int get totalMinutes => minutes.values.fold(0, (a, b) => a + b);

  factory EventExtras.fromMap(Map<String, dynamic> map) => EventExtras(
        tagId: map['tagId'] as String?,
        jira: JiraRef.fromMap(map['jira'] as Map<String, dynamic>?),
        title: map['title'] as String?,
        minutes: {
          for (final e in (map['minutes'] as Map<String, dynamic>? ?? {}).entries)
            e.key: (e.value as num).toInt(),
        },
      );

  Map<String, dynamic> toMap() => {
        'tagId': tagId,
        'jira': jira?.toMap(),
        'title': title,
        'minutes': minutes,
      };

  EventExtras copyWith({
    String? tagId,
    JiraRef? jira,
    String? title,
    Map<String, int>? minutes,
    bool clearTag = false,
    bool clearJira = false,
  }) =>
      EventExtras(
        tagId: clearTag ? null : tagId ?? this.tagId,
        jira: clearJira ? null : jira ?? this.jira,
        title: title ?? this.title,
        minutes: minutes ?? this.minutes,
      );

  /// An absolute total for one day; zero drops the day again.
  EventExtras withMinutes(String dayKey, int value) {
    final next = {...minutes};
    if (value <= 0) {
      next.remove(dayKey);
    } else {
      next[dayKey] = value.clamp(0, 24 * 60);
    }
    return copyWith(minutes: next);
  }
}
