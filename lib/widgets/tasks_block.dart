import 'package:flutter/material.dart';

import '../logic/jira_ref.dart';
import '../models/someday_item.dart';
import '../models/calendar_event.dart';
import '../models/tag.dart';
import '../models/task.dart';
import 'add_task_field.dart';
import 'block_frame.dart';
import 'task_tile.dart';

/// The day's untimed to-dos, with the add line underneath.
class TasksBlock extends StatelessWidget {
  const TasksBlock({
    super.key,
    required this.tasks,
    required this.tags,
    required this.shownDay,
    required this.onToggle,
    required this.onMenu,
    required this.onAdd,
    this.someday = const [],
    this.onPullSomeday,
    this.onOpenJira,
    this.onRename,
    this.onHoverTask,
    this.onHoverEvent,
  });

  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String shownDay;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;
  final void Function(String title, {String? tagId, String? time}) onAdd;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final void Function(JiraRef)? onOpenJira;

  /// Tapping a title renames that task. Null leaves them read-only.
  final void Function(Task)? onRename;

  /// Where the pointer is, for the keyboard shortcuts that act on it.
  final void Function(Task, bool hovering)? onHoverTask;
  final void Function(CalendarEvent, bool hovering)? onHoverEvent;

  @override
  Widget build(BuildContext context) {
    return BlockFrame(
      title: 'Tasks',
      icon: Icons.check_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final task in tasks)
            TaskTile(
              task: task,
              shownDay: shownDay,
              tag: tags[task.tagId],
              onToggle: () => onToggle(task),
              onMenu: () => onMenu(task),
              onOpenJira: onOpenJira,
              onRename: onRename == null ? null : () => onRename!(task),
              onHover: onHoverTask == null
                  ? null
                  : (hovering) => onHoverTask!(task, hovering),
            ),
          AddTaskField(
            onAdd: onAdd,
            tags: tags.values.toList(),
            someday: someday,
            onPullSomeday: onPullSomeday,
          ),
        ],
      ),
    );
  }
}
