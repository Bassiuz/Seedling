/// A quick thing you tick off each day: "Work travel: Home / OV / Bike", or a
/// plain yes/no like "Cycled today".
///
/// [options] empty means a plain check. Deactivating a question hides it from
/// new days without touching the answers already recorded against past ones.
class DailyQuestion {
  const DailyQuestion({
    required this.id,
    required this.label,
    required this.options,
    required this.sortOrder,
    this.emoji,
    this.active = true,
  });

  factory DailyQuestion.fromMap(String id, Map<String, dynamic> map) =>
      DailyQuestion(
        id: id,
        label: map['label'] as String? ?? '',
        options: (map['options'] as List<dynamic>? ?? const [])
            .map((o) => o as String)
            .toList(),
        sortOrder: map['sortOrder'] as int? ?? 0,
        emoji: map['emoji'] as String?,
        active: map['active'] as bool? ?? true,
      );

  final String id;
  final String label;

  /// Empty for a plain check; otherwise the choices offered as chips.
  final List<String> options;
  final int sortOrder;

  /// Used to bundle a question into a mood at a glance, like the week review.
  final String? emoji;
  final bool active;

  bool get isCheck => options.isEmpty;

  /// What a plain check stores when ticked.
  static const String checked = 'yes';

  Map<String, dynamic> toMap() => {
        'label': label,
        'options': options,
        'sortOrder': sortOrder,
        'emoji': emoji,
        'active': active,
      };

  DailyQuestion copyWith({
    String? label,
    List<String>? options,
    int? sortOrder,
    String? emoji,
    bool? active,
    bool clearEmoji = false,
  }) =>
      DailyQuestion(
        id: id,
        label: label ?? this.label,
        options: options ?? this.options,
        sortOrder: sortOrder ?? this.sortOrder,
        emoji: clearEmoji ? null : emoji ?? this.emoji,
        active: active ?? this.active,
      );
}
