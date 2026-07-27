import 'package:flutter/material.dart';

import '../models/tag.dart';
import '../models/task.dart';
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
  });

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
      child: tasks.isEmpty
          ? const EmptyNote('Nothing timed')
          : Column(
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
              ],
            ),
    );
  }
}
