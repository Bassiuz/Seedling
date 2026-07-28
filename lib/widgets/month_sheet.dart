import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/day_key.dart';
import '../logic/month_grid.dart';
import '../theme/seedling_theme.dart';

/// One month, Monday first. A day you did something on is drawn filled in, so
/// the gaps in a month are visible at a glance.
class MonthView extends StatelessWidget {
  const MonthView({
    super.key,
    required this.month,
    required this.onPick,
    this.activeDays = const {},
    this.selected,
    this.today,
  });

  /// Any day inside the month being drawn.
  final String month;
  final void Function(String dayKey) onPick;
  final Set<String> activeDays;
  final String? selected;
  final String? today;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final grid = monthGrid(month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(DateFormat('MMMM y', 'en_US').format(dateOfKey(month)),
            style: text.displaySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(label,
                      style: text.labelSmall?.copyWith(color: colors.muted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < 6; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _DayCircle(
                    dayKey: grid[row * 7 + col],
                    active: activeDays.contains(grid[row * 7 + col]),
                    selected: grid[row * 7 + col] == selected,
                    isToday: grid[row * 7 + col] == today,
                    onPick: onPick,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.dayKey,
    required this.active,
    required this.selected,
    required this.isToday,
    required this.onPick,
  });

  /// Null for the blanks either side of the month.
  final String? dayKey;
  final bool active;
  final bool selected;
  final bool isToday;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    if (dayKey == null) return const SizedBox(height: 44);

    return GestureDetector(
      onTap: () => onPick(dayKey!),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? colors.ink : null,
              border: Border.all(
                color: selected
                    ? colors.ink
                    : isToday
                        ? colors.muted
                        : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              '${dateOfKey(dayKey!).day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: active ? colors.paper : colors.ink,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Months you can swipe through, hanging from the top of the screen.
///
/// It comes down over the day rather than up from the bottom, because that is
/// the direction you pulled it from.
class MonthSheet extends StatefulWidget {
  const MonthSheet({
    super.key,
    required this.selected,
    required this.onPick,
    this.activeDays = const {},
    this.today,
  });

  final String selected;
  final void Function(String dayKey) onPick;
  final Set<String> activeDays;
  final String? today;

  /// Slides down over the page and returns the day picked, or null.
  static Future<String?> show(
    BuildContext context, {
    required String selected,
    Set<String> activeDays = const {},
    String? today,
  }) =>
      showGeneralDialog<String>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close the calendar',
        barrierColor: Colors.black26,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, _, _) => MonthSheet(
          selected: selected,
          activeDays: activeDays,
          today: today,
          onPick: (day) => Navigator.pop(dialogContext, day),
        ),
        transitionBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, -1), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  @override
  State<MonthSheet> createState() => _MonthSheetState();
}

class _MonthSheetState extends State<MonthSheet> {
  /// Page zero is the month you were on; swiping either way is unbounded.
  static const int _anchor = 6000;
  late final _controller = PageController(initialPage: _anchor);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  // Six rows, the weekday strip and the month name, without
                  // asking the PageView to measure its children.
                  height: 380,
                  child: PageView.builder(
                    controller: _controller,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: MonthView(
                        month: addMonths(widget.selected, index - _anchor),
                        activeDays: widget.activeDays,
                        selected: widget.selected,
                        today: widget.today,
                        onPick: widget.onPick,
                      ),
                    ),
                  ),
                ),
                // The handle you would grab to put it away again.
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  onVerticalDragEnd: (_) => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 56,
                    height: 24,
                    alignment: Alignment.center,
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.rule,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
