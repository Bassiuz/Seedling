import 'package:flutter/material.dart';

import '../data/seedling_repo.dart';
import '../logic/recent_emoji.dart';
import '../models/review_template.dart';
import '../models/week_review.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';

/// A written week review, without a repo behind it so it can be golden-tested.
class WeekReviewView extends StatelessWidget {
  const WeekReviewView({
    super.key,
    required this.review,
    required this.template,
    required this.onAnswer,
    required this.onAddMood,
    required this.onRemoveMood,
    this.recentEmoji = const [],
    this.showBack = true,
  });

  final WeekReview review;
  final ReviewTemplate template;
  final void Function(String question, String answer) onAnswer;
  final void Function(String emoji, String text) onAddMood;
  final void Function(int index) onRemoveMood;

  /// The quick strip, newest first. Falls back to the template's starters
  /// until something has actually been used.
  final List<String> recentEmoji;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (showBack) const BackLine(),
            Text('Week review', style: text.displayMedium),
            Text(review.weekKey, style: text.displaySmall),
            const SizedBox(height: 28),

            // The goals as they stood when this review was made — deliberately
            // read-only here, because a review is a record of that week.
            for (final block in review.goals) ...[
              BlockFrame(
                title: block.title,
                icon: Icons.flag_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (block.goals.isEmpty)
                      const EmptyNote('No goals set')
                    else
                      for (final goal in block.goals)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('› $goal', style: text.bodyLarge),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            for (final question in template.questions) ...[
              BlockFrame(
                title: question,
                icon: Icons.help_outline,
                child: _AnswerField(
                  initial: review.answers[question] ?? '',
                  onChanged: (value) => onAnswer(question, value),
                ),
              ),
              const SizedBox(height: 28),
            ],

            BlockFrame(
              title: 'Observations',
              icon: Icons.mood,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, line) in review.moodLines.indexed)
                    _MoodRow(line: line, onRemove: () => onRemoveMood(i)),
                  const SizedBox(height: 8),
                  _AddMood(
                    palette: recentEmoji.isEmpty
                        ? template.moodEmoji
                        : recentEmoji,
                    onAdd: onAddMood,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerField extends StatefulWidget {
  const _AnswerField({required this.initial, required this.onChanged});

  final String initial;
  final void Function(String) onChanged;

  @override
  State<_AnswerField> createState() => _AnswerFieldState();
}

class _AnswerFieldState extends State<_AnswerField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_AnswerField old) {
    super.didUpdateWidget(old);
    if (widget.initial != _controller.text) _controller.text = widget.initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: null,
      minLines: 3,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration.collapsed(
        hintText: 'Write…',
        hintStyle: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: colors.faint),
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.line, required this.onRemove});

  final MoodLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.emoji, style: text.titleMedium),
          const SizedBox(width: 10),
          Expanded(child: Text(line.text, style: text.bodyLarge)),
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: colors.faint),
          ),
        ],
      ),
    );
  }
}

class _AddMood extends StatefulWidget {
  const _AddMood({required this.palette, required this.onAdd});

  /// The quick strip: whatever you have reached for lately, newest first,
  /// falling back to the template's starters before you have used any.
  final List<String> palette;
  final void Function(String emoji, String text) onAdd;

  @override
  State<_AddMood> createState() => _AddMoodState();
}

class _AddMoodState extends State<_AddMood> {
  final _controller = TextEditingController();
  final _emojiController = TextEditingController();
  late String _emoji = widget.palette.isEmpty ? '•' : widget.palette.first;

  @override
  void dispose() {
    _controller.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    widget.onAdd(_emoji, value);
    _controller.clear();
  }

  /// Anything typed in the little box wins over the strip, so an emoji you have
  /// never used is one keystroke away rather than unavailable.
  void _typed(String raw) {
    final emoji = firstEmoji(raw);
    if (emoji == null) return;
    setState(() => _emoji = emoji);
    // Keep only the cluster we took, so the box shows what will be used.
    if (_emojiController.text != emoji) {
      _emojiController.value = TextEditingValue(
        text: emoji,
        selection: TextSelection.collapsed(offset: emoji.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final emoji in widget.palette)
              GestureDetector(
                onTap: () {
                  setState(() => _emoji = emoji);
                  _emojiController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: emoji == _emoji ? colors.ink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(emoji, style: text.titleMedium),
                ),
              ),
            // Any emoji, not just the ones on the strip.
            SizedBox(
              width: 52,
              child: TextField(
                controller: _emojiController,
                onChanged: _typed,
                textAlign: TextAlign.center,
                style: text.titleMedium,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '+',
                  hintStyle: text.titleMedium?.copyWith(color: colors.faint),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: colors.rule),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: colors.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(_emoji, style: text.titleMedium),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: _submit,
                textInputAction: TextInputAction.done,
                style: text.bodyLarge,
                decoration: InputDecoration.collapsed(
                  hintText: 'Add an observation…',
                  hintStyle: text.bodyLarge?.copyWith(color: colors.faint),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The live week review.
class WeekReviewScreen extends StatelessWidget {
  const WeekReviewScreen({
    super.key,
    required this.repo,
    required this.weekKey,
    this.showBack = true,
  });

  final SeedlingRepo repo;
  final String weekKey;

  /// False when the review is a page in the day pager rather than a pushed
  /// screen — there is nothing to go back to.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReviewTemplate>(
      stream: repo.watchReviewTemplate(),
      builder: (context, templateSnap) {
        final template = templateSnap.data;
        // Still waiting on the template. Draw the arrow anyway — a blank page
        // you cannot leave is worse than a slow one.
        if (template == null) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(padding: EdgeInsets.all(24), child: BackLine()),
            ),
          );
        }
        return StreamBuilder<List<String>>(
          stream: repo.watchRecentEmoji(),
          builder: (context, emojiSnap) => StreamBuilder<WeekReview?>(
          stream: repo.watchReview(weekKey),
          builder: (context, reviewSnap) {
            // Creating it lazily on first view is what freezes the goals: the
            // snapshot is taken the moment you sit down to write.
            final review =
                reviewSnap.data ?? WeekReview.from(weekKey, template);
            return WeekReviewView(
              review: review,
              template: template,
              showBack: showBack,
              recentEmoji: emojiSnap.data ?? const [],
              onAnswer: (question, answer) => repo.saveReview(
                WeekReview(
                  weekKey: review.weekKey,
                  goals: review.goals,
                  answers: {...review.answers, question: answer},
                  moodLines: review.moodLines,
                ),
              ),
              onAddMood: (emoji, text) {
                repo.saveReview(
                  WeekReview(
                    weekKey: review.weekKey,
                    goals: review.goals,
                    answers: review.answers,
                    moodLines: [
                      ...review.moodLines,
                      MoodLine(emoji: emoji, text: text),
                    ],
                  ),
                );
                // Reaching for one is what makes it recent.
                repo.noteEmojiUsed(emoji);
              },
              onRemoveMood: (index) => repo.saveReview(
                WeekReview(
                  weekKey: review.weekKey,
                  goals: review.goals,
                  answers: review.answers,
                  moodLines: [...review.moodLines]..removeAt(index),
                ),
              ),
            );
          },
        ),
        );
      },
    );
  }
}
