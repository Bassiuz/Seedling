/// The shape of a week review, configured once and reused every week.
///
/// Goals live here and are *copied* into each review when it is created, so a
/// review written in July keeps showing July's goals even after they change.
class ReviewTemplate {
  const ReviewTemplate({
    this.goalBlocks = const [],
    this.questions = const [],
    this.moodEmoji = const [],
  });

  factory ReviewTemplate.fromMap(Map<String, dynamic> map) => ReviewTemplate(
        goalBlocks: (map['goalBlocks'] as List<dynamic>? ?? const [])
            .map((b) => GoalBlock.fromMap(b as Map<String, dynamic>))
            .toList(),
        questions: (map['questions'] as List<dynamic>? ?? const [])
            .map((q) => q as String)
            .toList(),
        moodEmoji: (map['moodEmoji'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );

  /// Slow-changing goals, e.g. "Quarterly Goals — 2026" and "Yearly Goals".
  final List<GoalBlock> goalBlocks;

  /// The prompts answered every week.
  final List<String> questions;

  /// Offered when adding a mood line, so an observation gets bundled at a
  /// glance the way Bas already writes them.
  final List<String> moodEmoji;

  Map<String, dynamic> toMap() => {
        'goalBlocks': goalBlocks.map((b) => b.toMap()).toList(),
        'questions': questions,
        'moodEmoji': moodEmoji,
      };

  /// The defaults mirror the review Bas already writes by hand.
  static const starter = ReviewTemplate(
    goalBlocks: [
      GoalBlock(title: 'Quarterly Goals', goals: []),
      GoalBlock(title: 'Yearly Goals', goals: []),
    ],
    questions: [
      'What did I do since last week review?',
      'What is going to be a lasting memory of this week?',
      'What is something I want to leave behind in the last week?',
    ],
    moodEmoji: ['🤔', '⏲️', '😢', '😄', '🦴', '🎰', '💻', '🚴', '🎯'],
  );
}

class GoalBlock {
  const GoalBlock({required this.title, required this.goals});

  factory GoalBlock.fromMap(Map<String, dynamic> map) => GoalBlock(
        title: map['title'] as String? ?? '',
        goals: (map['goals'] as List<dynamic>? ?? const [])
            .map((g) => g as String)
            .toList(),
      );

  final String title;
  final List<String> goals;

  Map<String, dynamic> toMap() => {'title': title, 'goals': goals};
}
