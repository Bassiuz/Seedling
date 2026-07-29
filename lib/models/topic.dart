import '../logic/jira_ref.dart';

/// A standing thing you spend time on that never becomes a task.
///
/// "Meetings", "Wordpress onderhoud" — work that recurs forever and has a
/// ticket of its own, so it needs a row on the timesheet without anyone
/// pretending it is something you tick off.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    this.jira,
    this.minutes = const {},
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final JiraRef? jira;

  /// Minutes by day key.
  final Map<String, int> minutes;
  final int sortOrder;

  int minutesOn(String dayKey) => minutes[dayKey] ?? 0;

  factory Topic.fromMap(String id, Map<String, dynamic> map) => Topic(
        id: id,
        title: map['title'] as String? ?? '',
        jira: JiraRef.fromMap(map['jira'] as Map<String, dynamic>?),
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        minutes: {
          for (final e
              in (map['minutes'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: (e.value as num).toInt(),
        },
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'jira': jira?.toMap(),
        'sortOrder': sortOrder,
        'minutes': minutes,
      };

  /// An absolute total for one day; zero drops the day rather than storing it.
  Topic withMinutes(String dayKey, int value) {
    final next = {...minutes};
    if (value <= 0) {
      next.remove(dayKey);
    } else {
      next[dayKey] = value.clamp(0, 24 * 60);
    }
    return Topic(
        id: id,
        title: title,
        jira: jira,
        minutes: next,
        sortOrder: sortOrder);
  }
}
