import 'review_template.dart';

/// One written week review.
///
/// [goals] is a snapshot taken when the review was created, not a live read of
/// the template: what you were aiming at that week is part of the record.
class WeekReview {
  const WeekReview({
    required this.weekKey,
    this.goals = const [],
    this.answers = const {},
    this.moodLines = const [],
    this.memory = '',
    this.leaveBehind = '',
  });

  factory WeekReview.fromMap(String weekKey, Map<String, dynamic> map) =>
      WeekReview(
        weekKey: weekKey,
        goals: (map['goals'] as List<dynamic>? ?? const [])
            .map((b) => GoalBlock.fromMap(b as Map<String, dynamic>))
            .toList(),
        answers: {
          for (final e
              in (map['answers'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: e.value as String,
        },
        moodLines: (map['moodLines'] as List<dynamic>? ?? const [])
            .map((l) => MoodLine.fromMap(l as Map<String, dynamic>))
            .toList(),
      );

  final String weekKey;
  final List<GoalBlock> goals;

  /// Keyed by the question text, so re-wording a prompt in the template does
  /// not silently re-label an answer already written.
  final Map<String, String> answers;
  final List<MoodLine> moodLines;
  final String memory;
  final String leaveBehind;

  bool get isEmpty =>
      moodLines.isEmpty && answers.values.every((a) => a.trim().isEmpty);

  Map<String, dynamic> toMap() => {
        'goals': goals.map((b) => b.toMap()).toList(),
        'answers': answers,
        'moodLines': moodLines.map((l) => l.toMap()).toList(),
      };

  /// A fresh review for [weekKey], with the template's goals frozen into it.
  static WeekReview from(String weekKey, ReviewTemplate template) =>
      WeekReview(weekKey: weekKey, goals: template.goalBlocks);
}

/// One observation, bundled under an emoji.
class MoodLine {
  const MoodLine({required this.emoji, required this.text});

  factory MoodLine.fromMap(Map<String, dynamic> map) => MoodLine(
        emoji: map['emoji'] as String? ?? '',
        text: map['text'] as String? ?? '',
      );

  final String emoji;
  final String text;

  Map<String, dynamic> toMap() => {'emoji': emoji, 'text': text};
}
