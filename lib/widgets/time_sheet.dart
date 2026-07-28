import 'package:flutter/material.dart';

import '../logic/duration_input.dart';
import '../theme/seedling_theme.dart';

/// Logs work against a task or an appointment in quarter-hour steps.
///
/// Quarter hours because that is the unit the admin ends up in — anything
/// finer would be invented precision.
class TimeSheet extends StatefulWidget {
  const TimeSheet({
    super.key,
    required this.title,
    required this.minutes,
    required this.totalMinutes,
    required this.onChange,
    this.onSet,
  });

  final String title;

  /// Minutes already logged on the day being shown, and across every day.
  final int minutes;
  final int totalMinutes;

  /// Called with the signed number of minutes to add.
  final void Function(int deltaMinutes) onChange;

  /// Called with an absolute number of minutes for the day, from typing.
  /// Null leaves the sheet stepper-only.
  final void Function(int minutes)? onSet;

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
  State<TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<TimeSheet> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final minutes = parseDuration(raw);
    if (minutes == null) return;
    widget.onSet!(minutes);
    _typed.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = widget.minutes;

    return SafeArea(
      child: Padding(
        // Above the keyboard: typing a duration you cannot see is no use.
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: text.titleLarge),
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
                  onTap: () => widget.onChange(-TimeSheet.step),
                ),
                Text(TimeSheet.format(today), style: text.displaySmall),
                _StepButton(
                  icon: Icons.add,
                  tooltip: 'Another 15 minutes',
                  enabled: true,
                  onTap: () => widget.onChange(TimeSheet.step),
                ),
              ],
            ),
            if (widget.onSet != null) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _typed,
                onSubmitted: _submit,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'or type it: 3, 40, 3.5, 3:15',
                  hintStyle:
                      text.bodyLarge?.copyWith(color: colors.faint),
                  helperText:
                      'Under 15 counts as hours, from 15 up as minutes.',
                  helperStyle: text.labelMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.rule),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.rule),
                  ),
                ),
              ),
            ],
            if (widget.totalMinutes != today) ...[
              const SizedBox(height: 16),
              Text(
                '${TimeSheet.format(widget.totalMinutes)} across all days',
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
