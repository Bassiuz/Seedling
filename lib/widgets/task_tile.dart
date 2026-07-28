import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/day_key.dart';
import '../logic/rollover.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';
import 'tag_chip.dart';
import 'time_sheet.dart';

/// One task on a day page: a big round checkbox, the title, and a quiet line
/// underneath for its time, its tag, and where it came from.
///
/// A task checked off on a *later* day still appears here as history — it is
/// drawn faded and does not respond to taps, because undoing it belongs on the
/// day it was actually done.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.shownDay,
    required this.onToggle,
    required this.onMenu,
    this.tag,
    this.overdue = false,
  });

  final Task task;

  /// The day page this tile is being drawn on.
  final String shownDay;
  final Tag? tag;
  final VoidCallback onToggle;
  final VoidCallback onMenu;

  /// Its time has gone by today and it is still open, so it is drawn in red.
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final state = checkStateOn(task, shownDay);
    final text = Theme.of(context).textTheme;
    final done = state != TaskCheckState.open;
    final interactive = state != TaskCheckState.doneLater;

    return GestureDetector(
      onLongPress: onMenu,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskCheckbox(
              state: state,
              color: overdue
                  ? SeedlingPalette.red
                  : tag == null
                      ? colors.ink
                      : TagChip.colorOf(tag!),
              onTap: interactive ? onToggle : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      task.title,
                      style: text.bodyLarge?.copyWith(
                        color: done
                            ? colors.muted
                            : colors.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: colors.muted,
                      ),
                    ),
                  ),
                  _Footnote(
                      task: task,
                      shownDay: shownDay,
                      tag: tag,
                      overdue: overdue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The quiet line under a task title: time, tag chip, and origin or completion
/// note. Renders nothing when there is nothing to say.
class _Footnote extends StatelessWidget {
  const _Footnote(
      {required this.task,
      required this.shownDay,
      this.tag,
      this.overdue = false});

  final Task task;
  final String shownDay;
  final Tag? tag;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final logged = task.minutesOn(shownDay);
    final notes = <String>[
      if (task.time != null) task.time!,
      if (logged > 0) TimeSheet.format(logged),
      if (overdue) 'Overdue',
      ..._originNote(),
    ];

    if (notes.isEmpty && tag == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (tag != null) TagChip(tag!),
          if (notes.isNotEmpty)
            Text(
              notes.join(' · '),
              style: style?.copyWith(
                fontStyle: FontStyle.italic,
                color: overdue ? SeedlingPalette.red : null,
                fontWeight: overdue ? FontWeight.w600 : null,
              ),
            ),
        ],
      ),
    );
  }

  List<String> _originNote() {
    final state = checkStateOn(task, shownDay);
    if (state == TaskCheckState.doneLater) {
      return ['done ${DateFormat('EEE d', 'en_US').format(dateOfKey(task.completedOnDate!))}'];
    }
    if (task.date != shownDay) {
      return ['from ${DateFormat('MMM d', 'en_US').format(dateOfKey(task.date))}'];
    }
    return const [];
  }
}

/// The big round checkbox. Deliberately oversized: it is the one control that
/// has to be easy to hit on a slow e-ink screen.
class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({
    super.key,
    required this.state,
    required this.color,
    this.onTap,
  });

  final TaskCheckState state;

  /// The tag's colour, or ink for an untagged task.
  final Color color;

  /// Null when the tile is history and must not respond.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final checkedHere = state == TaskCheckState.checkedHere;
    final doneLater = state == TaskCheckState.doneLater;
    final outline = doneLater ? colors.faint : color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checkedHere ? color : null,
          border: Border.all(color: outline, width: 2),
        ),
        child: state == TaskCheckState.open
            ? null
            : Icon(
                Icons.check,
                size: doneLater ? 14 : 18,
                color:
                    checkedHere ? colors.paper : colors.muted,
              ),
      ),
    );
  }
}
