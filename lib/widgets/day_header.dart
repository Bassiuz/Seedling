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
    this.onOpenReview,
    this.reviewDue = false,
    this.onToggleReveal,
    this.revealing = false,
    this.onOpenSomeday,
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

  /// Opens the week review. Badged while one is waiting to be written.
  final VoidCallback? onOpenReview;
  final bool reviewDue;

  /// Long-pressing the date shows hidden calendar events, so a wrong hide can
  /// be undone on a phone or the BigMe — neither has the keyboard shortcut.
  final VoidCallback? onToggleReveal;
  final bool revealing;

  /// The someday list, reachable from the day rather than buried in settings.
  final VoidCallback? onOpenSomeday;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final date = dateOfKey(dayKey);

    return Padding(
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
              if (onOpenReview != null)
                IconButton(
                  onPressed: onOpenReview,
                  tooltip: 'Week review',
                  icon: Badge(
                    isLabelVisible: reviewDue,
                    child: Icon(Icons.rate_review_outlined,
                        color: colors.muted),
                  ),
                ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE', 'en_US').format(date),
                    style: text.displayMedium),
                Text(DateFormat('MMMM d, y', 'en_US').format(date),
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
        ],
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
