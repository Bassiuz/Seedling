import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../logic/day_key.dart';
import '../logic/standup.dart';
import '../models/calendar_event.dart';
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
  const StandupView({
    super.key,
    required this.standup,
    this.tags = const {},
    this.name = '',
    this.onShiftPrevious,
  });

  final Standup standup;
  final Map<String, Tag> tags;

  /// Heads the copied text. Empty leaves it off.
  final String name;

  /// Moves which day is being looked back at, by a day at a time. Most weeks
  /// the guess is right; the weeks it is not are the ones you notice.
  final void Function(int delta)? onShiftPrevious;

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
            Row(
              children: [
                const Expanded(child: BackLine()),
                _CopyButton(text: standupText(standup, name: name)),
              ],
            ),
            Text('Standup', style: text.displayMedium),
            Text(DateFormat('MMMM d, y', 'en_US').format(dateOfKey(standup.day)),
                style: text.displaySmall),
            const SizedBox(height: 28),
            BlockFrame(
              title: '${_heading(standup.previousDay)} — done',
              icon: Icons.check_circle_outline,
              trailing: onShiftPrevious == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Shift(
                          tooltip: 'A day earlier',
                          icon: Icons.chevron_left,
                          onTap: () => onShiftPrevious!(-1),
                        ),
                        _Shift(
                          tooltip: 'A day later',
                          icon: Icons.chevron_right,
                          onTap: () => onShiftPrevious!(1),
                        ),
                      ],
                    ),
              child: _List(
                tasks: standup.done,
                events: standup.attended,
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
                events: standup.meetings,
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
    this.events = const [],
    this.strikeDone = false,
  });

  /// Meetings come first: they are the fixed points of the day, and the ones
  /// other people already know about.
  final List<CalendarEvent> events;
  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String empty;

  /// Today's list keeps what is already finished, struck through, so the two
  /// halves of the standup do not contradict each other.
  final bool strikeDone;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty && events.isEmpty) return EmptyNote(empty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in events)
          _Line(
            title: event.title,
            note: event.allDay ? 'All day' : event.time,
            icon: Icons.groups_outlined,
          ),
        for (final task in tasks)
          _Line(
            title: task.title,
            note: task.time,
            tag: tags[task.tagId],
            struck: strikeDone && task.isCompleted,
          ),
      ],
    );
  }
}

/// Nudges which day the standup looks back at. Deliberately small: it is a
/// correction, not a control you should notice most mornings.
class _Shift extends StatelessWidget {
  const _Shift({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: colors.faint),
    );
  }
}

/// One thing you would say out loud.
class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    this.note,
    this.tag,
    this.icon,
    this.struck = false,
  });

  final String title;
  final String? note;
  final Tag? tag;

  /// Marks a meeting. Tasks get the plain bullet.
  final IconData? icon;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: icon == null
                ? Text('\u203A',
                    style: text.bodyLarge?.copyWith(color: colors.faint))
                : Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(icon, size: 16, color: colors.muted),
                  ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: text.bodyLarge?.copyWith(
                    color: struck ? colors.muted : colors.ink,
                    decoration: struck ? TextDecoration.lineThrough : null,
                    decorationColor: colors.muted,
                  ),
                ),
                if (note != null)
                  Text(note!,
                      style: text.labelSmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                if (tag != null) TagChip(tag!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Puts the whole standup on the clipboard, ready to paste into Slack.
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return IconButton(
      tooltip: 'Copy for Slack',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Standup copied')),
        );
      },
      icon: Icon(Icons.copy_all_outlined, color: colors.muted),
    );
  }
}

/// The live standup: works out which day to look back at, and lets you move
/// it when the week did not go the usual way.
class StandupScreen extends StatefulWidget {
  const StandupScreen({
    super.key,
    required this.day,
    required this.tasks,
    required this.tags,
    required this.eventsFor,
    this.name = '',
    this.workingDays = defaultWorkingDays,
    this.daysOff = const {},
  });

  final String day;
  final List<Task> tasks;
  final Map<String, Tag> tags;

  /// The appointments on a day, which the day page already has loaded.
  final List<CalendarEvent> Function(String dayKey) eventsFor;

  final String name;
  final Set<int> workingDays;
  final Set<String> daysOff;

  @override
  State<StandupScreen> createState() => _StandupScreenState();
}

class _StandupScreenState extends State<StandupScreen> {
  late String _previous = previousWorkingDay(
    widget.day,
    workingDays: widget.workingDays,
    daysOff: widget.daysOff,
  );

  @override
  Widget build(BuildContext context) {
    return StandupView(
      name: widget.name,
      tags: widget.tags,
      standup: standupFor(
        widget.tasks,
        widget.day,
        previousDay: _previous,
        events: widget.eventsFor(widget.day),
        previousEvents: widget.eventsFor(_previous),
      ),
      onShiftPrevious: (delta) => setState(() {
        final moved = addDays(_previous, delta);
        // It has to stay in the past, and a fortnight back is already further
        // than anyone means.
        if (moved.compareTo(widget.day) >= 0) return;
        if (moved.compareTo(addDays(widget.day, -14)) < 0) return;
        _previous = moved;
      }),
    );
  }
}
