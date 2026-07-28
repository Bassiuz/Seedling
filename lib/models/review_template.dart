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

  /// Editing goal lists. Pure so the rules can be tested without a screen.
  ReviewTemplate _withBlocks(List<GoalBlock> blocks) => ReviewTemplate(
        goalBlocks: blocks,
        questions: questions,
        moodEmoji: moodEmoji,
      );

  /// Adds [goal] to the list called [blockTitle], leaving the others alone.
  ReviewTemplate withGoalAdded(String blockTitle, String goal) =>
      _withBlocks([
        for (final block in goalBlocks)
          if (block.title == blockTitle)
            GoalBlock(title: block.title, goals: [...block.goals, goal])
          else
            block,
      ]);

  ReviewTemplate withGoalRemoved(String blockTitle, int index) => _withBlocks([
        for (final block in goalBlocks)
          if (block.title == blockTitle && index < block.goals.length)
            GoalBlock(
              title: block.title,
              goals: [...block.goals]..removeAt(index),
            )
          else
            block,
      ]);

  /// A new, empty list. A title already in use is left as it is rather than
  /// duplicated.
  ReviewTemplate withBlockAdded(String title) =>
      goalBlocks.any((b) => b.title == title)
          ? this
          : _withBlocks([...goalBlocks, GoalBlock(title: title, goals: const [])]);

  /// The defaults mirror the review Bas already writes by hand.
  static const starter = ReviewTemplate(
    goalBlocks: [
      GoalBlock(title: 'Quarterly Goals', goals: []),
      GoalBlock(title: 'Yearly Goals', goals: []),
    ],
    questions: [
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
