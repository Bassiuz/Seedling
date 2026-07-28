import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/day_key.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';

/// The top of a day page: the yesterday/today/tomorrow shortcuts, and the date
/// written out the way you would write it at the top of a notebook page.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.dayKey,
    required this.today,
    required this.onJump,
    this.onOpenSettings,
    this.onToggleReveal,
    this.revealing = false,
    this.onOpenSomeday,
    this.onOpenCalendar,
    this.trailing,
    this.title,
    this.subtitle,
  });

  /// The day being shown.
  final String dayKey;

  /// The real today, so the shortcuts know what they point at.
  final String today;

  /// Called with the offset from [today] of the day to jump to.
  final void Function(int deltaFromToday) onJump;

  /// Null hides the settings button, which is what golden tests of the bare
  /// header want.
  final VoidCallback? onOpenSettings;

  /// Long-pressing the date shows hidden calendar events, so a wrong hide can
  /// be undone on a phone or the BigMe — neither has the keyboard shortcut.
  final VoidCallback? onToggleReveal;
  final bool revealing;

  /// The someday list, reachable from the day rather than buried in settings.
  final VoidCallback? onOpenSomeday;

  /// Dragging the header down brings the month calendar with it. The gesture
  /// lives up here rather than on the page: the day's own blocks scroll, and
  /// a downward drag inside them means scroll, not "show me the month".
  final VoidCallback? onOpenCalendar;

  /// Sits beside the date, aligned with the top of it. The day's check-offs
  /// go here once they are all answered and have folded to one line.
  final Widget? trailing;

  /// What the page is, when it is not a date — a week review, say.
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final date = dateOfKey(dayKey);

    return GestureDetector(
      onVerticalDragEnd: onOpenCalendar == null
          ? null
          : (details) {
              if ((details.primaryVelocity ?? 0) > 0) onOpenCalendar!();
            },
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onOpenSomeday == null
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: onOpenSomeday,
                          tooltip: 'Someday',
                          icon: Icon(Icons.cloud_outlined, color: colors.muted),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.rule,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (label, delta) in const [
                      ('Yesterday', -1),
                      ('Today', 0),
                      ('Tomorrow', 1),
                    ])
                      DayShortcut(
                        label: label,
                        selected: dayKey == addDays(today, delta),
                        onTap: () => onJump(delta),
                      ),
                  ],
                ),
              ),
              // Settings is pinned to the right rather than sharing space
              // with whatever else is on the row.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: onOpenSettings == null
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: onOpenSettings,
                          tooltip: 'Settings',
                          icon: Icon(Icons.settings_outlined,
                              color: colors.muted),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onLongPress: onToggleReveal,
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The date takes what is left; the summary beside it is only
                // as wide as it needs to be.
                Expanded(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? DateFormat('EEEE', 'en_US').format(date),
                    style: text.displayMedium),
                Text(
                    subtitle ??
                        DateFormat('MMMM d, y', 'en_US').format(date),
                    style: text.displaySmall),
                if (revealing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Showing hidden events — long-press the date to stop',
                      style: text.labelMedium
                          ?.copyWith(color: SeedlingPalette.crimson),
                    ),
                  ),
              ],
            ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: trailing!,
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

/// One segment of the day-shortcut pill.
class DayShortcut extends StatelessWidget {
  const DayShortcut({
    super.key,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.paper : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? colors.ink
                    : colors.muted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
