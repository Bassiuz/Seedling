import '../logic/jira_ref.dart';

/// A to-do item.
///
/// All dates are day keys (`yyyy-MM-dd`, see `lib/logic/day_key.dart`).
/// [date] is the day the task is planned for and moves when it is snoozed;
/// [createdDate] never moves. [completedOnDate] records *which day page* the
/// task was checked off on — the rollover rule in `lib/logic/rollover.dart`
/// needs that, not just a completed flag.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.date,
    required this.createdDate,
    this.tagId,
    this.time,
    this.completedOnDate,
    this.timeEntries = const {},
    this.jira,
  });

  factory Task.fromMap(String id, Map<String, dynamic> map) => Task(
        id: id,
        title: map['title'] as String? ?? '',
        date: map['date'] as String? ?? '',
        createdDate: map['createdDate'] as String? ?? '',
        tagId: map['tagId'] as String?,
        time: map['time'] as String?,
        completedOnDate: map['completedOnDate'] as String?,
        jira: JiraRef.fromMap(map['jira'] as Map<String, dynamic>?),
        timeEntries: {
          for (final e
              in (map['timeEntries'] as Map<String, dynamic>? ?? const {})
                  .entries)
            e.key: (e.value as num).toInt(),
        },
      );

  final String id;
  final String title;
  final String date;
  final String createdDate;
  final String? tagId;

  /// `HH:mm`, or null for an untimed task.
  final String? time;
  final String? completedOnDate;

  /// The Jira ticket this task is about, if any.
  final JiraRef? jira;

  /// Minutes worked, keyed by the day they were worked on — the admin Bas
  /// needs later is per day, not just a running total.
  final Map<String, int> timeEntries;

  bool get isCompleted => completedOnDate != null;
  bool get isTimed => time != null;

  int get totalMinutes =>
      timeEntries.values.fold(0, (sum, minutes) => sum + minutes);

  int minutesOn(String dayKey) => timeEntries[dayKey] ?? 0;

  /// [id] is the document id, so it is not part of the stored data.
  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date,
        'createdDate': createdDate,
        'tagId': tagId,
        'time': time,
        'completedOnDate': completedOnDate,
        'timeEntries': timeEntries,
        'jira': jira?.toMap(),
      };

  /// [clearCompleted] is the only way to set [completedOnDate] back to null:
  /// an omitted named parameter cannot be told apart from an explicit null.
  Task copyWith({
    String? title,
    String? date,
    String? tagId,
    String? time,
    String? completedOnDate,
    Map<String, int>? timeEntries,
    JiraRef? jira,
    bool clearJira = false,
    bool clearCompleted = false,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        createdDate: createdDate,
        tagId: tagId ?? this.tagId,
        time: time ?? this.time,
        completedOnDate:
            clearCompleted ? null : completedOnDate ?? this.completedOnDate,
        timeEntries: timeEntries ?? this.timeEntries,
        jira: clearJira ? null : jira ?? this.jira,
      );
}
