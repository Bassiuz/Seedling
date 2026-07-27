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
  });

  factory Task.fromMap(String id, Map<String, dynamic> map) => Task(
        id: id,
        title: map['title'] as String? ?? '',
        date: map['date'] as String? ?? '',
        createdDate: map['createdDate'] as String? ?? '',
        tagId: map['tagId'] as String?,
        time: map['time'] as String?,
        completedOnDate: map['completedOnDate'] as String?,
      );

  final String id;
  final String title;
  final String date;
  final String createdDate;
  final String? tagId;

  /// `HH:mm`, or null for an untimed task.
  final String? time;
  final String? completedOnDate;

  bool get isCompleted => completedOnDate != null;
  bool get isTimed => time != null;

  /// [id] is the document id, so it is not part of the stored data.
  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date,
        'createdDate': createdDate,
        'tagId': tagId,
        'time': time,
        'completedOnDate': completedOnDate,
      };

  /// [clearCompleted] is the only way to set [completedOnDate] back to null:
  /// an omitted named parameter cannot be told apart from an explicit null.
  Task copyWith({
    String? title,
    String? date,
    String? tagId,
    String? time,
    String? completedOnDate,
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
      );
}
