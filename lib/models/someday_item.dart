/// Something you want to do eventually, parked against a project.
///
/// [priority] is a plain sort key, lowest first — the list is ordered so the
/// pull-into-today flow can offer the top few without asking you to choose from
/// everything.
class SomedayItem {
  const SomedayItem({
    required this.id,
    required this.title,
    required this.priority,
    this.tagId,
  });

  factory SomedayItem.fromMap(String id, Map<String, dynamic> map) =>
      SomedayItem(
        id: id,
        title: map['title'] as String? ?? '',
        priority: map['priority'] as int? ?? 0,
        tagId: map['tagId'] as String?,
      );

  final String id;
  final String title;
  final int priority;

  /// Null means the item is not filed under any project.
  final String? tagId;

  Map<String, dynamic> toMap() => {
        'title': title,
        'priority': priority,
        'tagId': tagId,
      };

  SomedayItem copyWith({String? title, int? priority}) => SomedayItem(
        id: id,
        title: title ?? this.title,
        priority: priority ?? this.priority,
        tagId: tagId,
      );
}
