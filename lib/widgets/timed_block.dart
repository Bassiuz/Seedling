import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/seedling_theme.dart';
import 'block_frame.dart';
import 'task_tile.dart';

/// Everything on the day that happens at a time, in clock order.
class TimedBlock extends StatelessWidget {
  const TimedBlock({
    super.key,
    required this.tasks,
    required this.tags,
    required this.shownDay,
    required this.onToggle,
    required this.onMenu,
    this.events = const [],
    this.onHideEvent,
    this.onUnhideEvent,
    this.revealing = false,
    this.hiddenKeys = const {},
  });

  /// Appointments read from the device calendar, already filtered unless
  /// [revealing].
  final List<CalendarEvent> events;
  final void Function(CalendarEvent)? onHideEvent;
  final void Function(CalendarEvent)? onUnhideEvent;

  /// True while hidden events are being shown so a hide can be undone.
  final bool revealing;
  final Set<String> hiddenKeys;

  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String shownDay;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;

  @override
  Widget build(BuildContext context) {
    return BlockFrame(
      title: 'Timed',
      icon: Icons.schedule,
      child: tasks.isEmpty && events.isEmpty
          ? const EmptyNote('Nothing timed')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final event in events)
                  EventRow(
                    event: event,
                    hidden: hiddenKeys.contains(event.hideKey),
                    onHide:
                        onHideEvent == null ? null : () => onHideEvent!(event),
                    onUnhide: onUnhideEvent == null
                        ? null
                        : () => onUnhideEvent!(event),
                  ),
                for (final task in tasks)
                  TaskTile(
                    task: task,
                    shownDay: shownDay,
                    tag: tags[task.tagId],
                    onToggle: () => onToggle(task),
                    onMenu: () => onMenu(task),
                  ),
              ],
            ),
    );
  }
}

/// One appointment. No checkbox: a calendar event is not something you tick
/// off here, it is context for the day. Long-press hides it for good.
class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.event,
    this.hidden = false,
    this.onHide,
    this.onUnhide,
  });

  final CalendarEvent event;

  /// True only while revealing — a hidden event is otherwise never drawn.
  final bool hidden;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onLongPress: hidden ? onUnhide : onHide,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Icon(
                event.allDay ? Icons.event : Icons.schedule,
                size: 20,
                color: hidden ? colors.faint : colors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: text.bodyLarge?.copyWith(
                      color: hidden ? colors.faint : colors.ink,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (event.allDay) 'All day' else event.time ?? '',
                        if (hidden) 'hidden',
                      ].where((p) => p.isNotEmpty).join(' · '),
                      style: text.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            if (hidden && onUnhide != null)
              IconButton(
                tooltip: 'Show this again',
                onPressed: onUnhide,
                icon: Icon(Icons.undo, size: 18, color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
