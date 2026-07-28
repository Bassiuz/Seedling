import 'package:flutter/material.dart';

import '../models/daily_question.dart';
import '../theme/seedling_theme.dart';
import 'block_frame.dart';

/// The day's quick check-offs.
///
/// Once every question has an answer the block folds itself into a single
/// "All answered · 2/2" line — the point of these is to be recorded and then
/// get out of the way. Tap that line to open it again.
class QuestionsBlock extends StatefulWidget {
  const QuestionsBlock({
    super.key,
    required this.questions,
    required this.answers,
    required this.onAnswer,
  });

  /// Active questions only; the day page filters the deactivated ones out.
  final List<DailyQuestion> questions;
  final Map<String, String> answers;

  /// A null value clears the answer.
  final void Function(DailyQuestion question, String? value) onAnswer;

  static bool allAnswered(
          List<DailyQuestion> questions, Map<String, String> answers) =>
      questions.isNotEmpty &&
      questions.every((q) => answers[q.id] != null);

  @override
  State<QuestionsBlock> createState() => _QuestionsBlockState();
}

class _QuestionsBlockState extends State<QuestionsBlock> {
  /// Set once you open a completed block by hand, so it does not slam shut
  /// again while you are changing an answer.
  bool _expandedByHand = false;

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const SizedBox.shrink();

    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final answered =
        widget.questions.where((q) => widget.answers[q.id] != null).length;
    final complete =
        QuestionsBlock.allAnswered(widget.questions, widget.answers);

    // Collapsed it is a single line: heading, summary and the chevron all in
    // one row, so it can sit beside the date without stacking.
    if (complete && !_expandedByHand) {
      return GestureDetector(
        onTap: () => setState(() => _expandedByHand = true),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 16, color: colors.muted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Daily — all answered $answered/${widget.questions.length}',
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(color: colors.muted),
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: colors.muted),
          ],
        ),
      );
    }

    return BlockFrame(
      title: 'Daily',
      icon: Icons.task_alt,
      trailing: complete
          ? IconButton(
              tooltip: 'Collapse',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _expandedByHand = false),
              icon: Icon(Icons.expand_less, color: colors.muted),
            )
          : null,
      child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final question in widget.questions)
                  _QuestionRow(
                    question: question,
                    answer: widget.answers[question.id],
                    onAnswer: (value) => widget.onAnswer(question, value),
                  ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final DailyQuestion question;
  final String? answer;
  final void Function(String?) onAnswer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (question.emoji != null) ...[
                Text(question.emoji!, style: text.bodyMedium),
                const SizedBox(width: 6),
              ],
              Expanded(child: Text(question.label, style: text.bodyMedium)),
              if (question.isCheck)
                QuestionCheck(
                  on: answer != null,
                  onTap: () =>
                      onAnswer(answer == null ? DailyQuestion.checked : null),
                ),
            ],
          ),
          if (!question.isCheck)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final option in question.options)
                    _OptionChip(
                      label: option,
                      selected: answer == option,
                      // Tapping the chosen one again clears it.
                      onTap: () => onAnswer(answer == option ? null : option),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.ink : null,
          border: Border.all(
            color: selected ? colors.ink : colors.faint,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.paper : colors.muted,
              ),
        ),
      ),
    );
  }
}

/// A smaller sibling of the task checkbox — these are secondary to the tasks.
class QuestionCheck extends StatelessWidget {
  const QuestionCheck({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? colors.ink : null,
          border: Border.all(color: on ? colors.ink : colors.faint, width: 2),
        ),
        child: on ? Icon(Icons.check, size: 15, color: colors.paper) : null,
      ),
    );
  }
}
