import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/day_key.dart';
import '../theme/seedling_palette.dart';

/// The top of a day page: the yesterday/today/tomorrow shortcuts, and the date
/// written out the way you would write it at the top of a notebook page.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.dayKey,
    required this.today,
    required this.onJump,
    this.onOpenTags,
  });

  /// The day being shown.
  final String dayKey;

  /// The real today, so the shortcuts know what they point at.
  final String today;

  /// Called with the offset from [today] of the day to jump to.
  final void Function(int deltaFromToday) onJump;

  /// Null hides the tags button, which is what golden tests of the bare header
  /// want.
  final VoidCallback? onOpenTags;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final date = dateOfKey(dayKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: SeedlingPalette.paperLine,
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
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: onOpenTags == null
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: onOpenTags,
                          tooltip: 'Tags',
                          icon: const Icon(Icons.label_outline,
                              color: SeedlingPalette.grayDark),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(DateFormat('EEEE', 'en_US').format(date),
              style: text.displayMedium),
          Text(DateFormat('MMMM d, y', 'en_US').format(date),
              style: text.displaySmall),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? SeedlingPalette.paper : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? SeedlingPalette.ink
                    : SeedlingPalette.grayDark,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
