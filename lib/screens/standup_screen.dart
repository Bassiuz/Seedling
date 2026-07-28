import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/day_key.dart';
import '../logic/standup.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';
import '../widgets/tag_chip.dart';

/// What you would say at a standup: what you finished yesterday, and what you
/// are on today.
///
/// Deliberately read-only. It is something to read out, so nothing here takes
/// a tap — no checkboxes, no menus, nothing to change by accident while you
/// are talking.
class StandupView extends StatelessWidget {
  const StandupView({super.key, required this.standup, this.tags = const {}});

  final Standup standup;
  final Map<String, Tag> tags;

  static String _heading(String dayKey) =>
      DateFormat('EEEE', 'en_US').format(dateOfKey(dayKey));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BackLine(),
            Text('Standup', style: text.displayMedium),
            Text(DateFormat('MMMM d, y', 'en_US').format(dateOfKey(standup.day)),
                style: text.displaySmall),
            const SizedBox(height: 28),
            BlockFrame(
              title: '${_heading(standup.previousDay)} — done',
              icon: Icons.check_circle_outline,
              child: _List(
                tasks: standup.done,
                tags: tags,
                empty: 'Nothing checked off',
              ),
            ),
            const SizedBox(height: 28),
            BlockFrame(
              title: 'Today',
              icon: Icons.today_outlined,
              child: _List(
                tasks: standup.planned,
                tags: tags,
                empty: 'Nothing on the list yet',
                strikeDone: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.tasks,
    required this.tags,
    required this.empty,
    this.strikeDone = false,
  });

  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String empty;

  /// Today's list keeps what is already finished, struck through, so the two
  /// halves of the standup do not contradict each other.
  final bool strikeDone;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return EmptyNote(empty);

    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('› ', style: text.bodyLarge?.copyWith(color: colors.faint)),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        task.title,
                        style: text.bodyLarge?.copyWith(
                          color: strikeDone && task.isCompleted
                              ? colors.muted
                              : colors.ink,
                          decoration: strikeDone && task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colors.muted,
                        ),
                      ),
                      if (task.time != null)
                        Text(task.time!,
                            style: text.labelSmall
                                ?.copyWith(fontStyle: FontStyle.italic)),
                      if (tags[task.tagId] != null)
                        TagChip(tags[task.tagId]!),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
