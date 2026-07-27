import 'package:flutter/material.dart';

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
  });

  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String shownDay;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;
  final void Function(String title, {String? tagId, String? time}) onAdd;

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
            ),
          AddTaskField(onAdd: onAdd, tags: tags.values.toList()),
        ],
      ),
    );
  }
}
