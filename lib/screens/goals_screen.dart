import 'package:flutter/material.dart';

import '../data/seedling_repo.dart';
import '../models/review_template.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';

/// The goals a week review snapshots, without a repo behind it.
///
/// These change a few times a year, which is why they live here rather than in
/// the review itself — a review is a record of the week, and editing it should
/// never rewrite what you were aiming at back then.
class GoalsView extends StatelessWidget {
  const GoalsView({
    super.key,
    required this.template,
    required this.onAddGoal,
    required this.onRemoveGoal,
    required this.onRemoveBlock,
  });

  final ReviewTemplate template;
  final void Function(String blockTitle, String goal) onAddGoal;
  final void Function(String blockTitle, int index) onRemoveGoal;
  final void Function(String title) onRemoveBlock;

  /// The lists Seedling ships with, which stay put.
  static const standing = {'Quarterly Goals', 'Yearly Goals'};

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BackLine(),
            Text('Goals', style: text.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Copied into each week review as it is written, so an old review '
              'keeps showing what you were aiming at then.',
              style: text.labelMedium,
            ),
            const SizedBox(height: 24),
            if (template.goalBlocks.isEmpty)
              const EmptyNote('No goal lists yet'),
            for (final block in template.goalBlocks) ...[
              BlockFrame(
                title: block.title,
                icon: Icons.flag_outlined,
                // The two standing lists have no × — they are the point of
                // this screen. Anything else you ended up with still does.
                trailing: GoalsView.standing.contains(block.title)
                    ? null
                    : IconButton(
                        tooltip: 'Remove this list',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onRemoveBlock(block.title),
                        icon:
                            Icon(Icons.close, size: 18, color: colors.faint),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, goal) in block.goals.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text('› $goal', style: text.bodyLarge),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onRemoveGoal(block.title, i),
                              icon: Icon(Icons.close,
                                  size: 18, color: colors.faint),
                            ),
                          ],
                        ),
                      ),
                    _AddLine(
                      hint: 'Add a goal…',
                      onAdd: (goal) => onAddGoal(block.title, goal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddLine extends StatefulWidget {
  const _AddLine({required this.hint, required this.onAdd});

  final String hint;
  final void Function(String) onAdd;

  @override
  State<_AddLine> createState() => _AddLineState();
}

class _AddLineState extends State<_AddLine> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    widget.onAdd(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.add, size: 18, color: colors.faint),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: _submit,
            textInputAction: TextInputAction.done,
            style: text.bodyLarge,
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: text.bodyLarge?.copyWith(color: colors.faint),
            ),
          ),
        ),
      ],
    );
  }
}

/// The live goals screen.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.repo});

  final SeedlingRepo repo;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ReviewTemplate>(
      stream: repo.watchReviewTemplate(),
      builder: (context, snapshot) {
        final template = snapshot.data;
        if (template == null) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(padding: EdgeInsets.all(24), child: BackLine()),
            ),
          );
        }
        return GoalsView(
          template: template,
          onAddGoal: (blockTitle, goal) =>
              repo.saveReviewTemplate(template.withGoalAdded(blockTitle, goal)),
          onRemoveGoal: (blockTitle, index) => repo
              .saveReviewTemplate(template.withGoalRemoved(blockTitle, index)),
          onRemoveBlock: (title) =>
              repo.saveReviewTemplate(template.withBlockRemoved(title)),
        );
      },
    );
  }
}
