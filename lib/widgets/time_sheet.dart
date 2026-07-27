import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/seedling_theme.dart';

/// Logs work against a task in quarter-hour steps.
///
/// Quarter hours because that is the unit the admin ends up in — anything
/// finer would be invented precision.
class TimeSheet extends StatelessWidget {
  const TimeSheet({
    super.key,
    required this.task,
    required this.dayKey,
    required this.onChange,
  });

  final Task task;
  final String dayKey;

  /// Called with the signed number of minutes to add.
  final void Function(int deltaMinutes) onChange;

  static const int step = 15;

  /// "1h 30m", "45m", or "none" — short enough for the tile footnote.
  static String format(int minutes) {
    if (minutes <= 0) return 'none';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = task.minutesOn(dayKey);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(task.title, style: text.titleLarge),
            const SizedBox(height: 4),
            Text('Time logged on this day', style: text.labelMedium),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepButton(
                  icon: Icons.remove,
                  tooltip: 'Less 15 minutes',
                  enabled: today > 0,
                  onTap: () => onChange(-step),
                ),
                Text(format(today), style: text.displaySmall),
                _StepButton(
                  icon: Icons.add,
                  tooltip: 'Another 15 minutes',
                  enabled: true,
                  onTap: () => onChange(step),
                ),
              ],
            ),
            if (task.totalMinutes != today) ...[
              const SizedBox(height: 16),
              Text(
                '${format(task.totalMinutes)} across all days',
                style: text.labelMedium?.copyWith(color: colors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      iconSize: 28,
      icon: Icon(icon, color: enabled ? colors.ink : colors.faint),
    );
  }
}
