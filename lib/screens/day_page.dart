import 'dart:async';

import 'package:flutter/material.dart';

import '../data/seedling_repo.dart';
import '../logic/day_key.dart';
import '../logic/rollover.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../widgets/day_header.dart';
import '../widgets/note_block.dart';
import '../widgets/tasks_block.dart';
import '../widgets/timed_block.dart';
import 'tags_screen.dart';

/// One day, laid out for whatever screen it lands on. Purely presentational so
/// every layout can be golden-tested without Firebase.
class DayView extends StatelessWidget {
  const DayView({
    super.key,
    required this.dayKey,
    required this.today,
    required this.tasks,
    required this.tags,
    required this.note,
    required this.onJump,
    required this.onToggle,
    required this.onMenu,
    required this.onAdd,
    required this.onNoteChanged,
    this.onOpenTags,
  });

  /// Already filtered and sorted for this day by `tasksForDay`.
  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String dayKey;
  final String today;
  final String note;
  final void Function(int deltaFromToday) onJump;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;
  final void Function(String title, {String? tagId, String? time}) onAdd;
  final void Function(String) onNoteChanged;
  final VoidCallback? onOpenTags;

  /// Below this the blocks stack; above it they sit side by side.
  static const double twoColumnWidth = 600;

  /// Above this the note gets a column of its own.
  static const double threeColumnWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final timed = tasks.where((t) => t.isTimed).toList();
    final untimed = tasks.where((t) => !t.isTimed).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayHeader(
              dayKey: dayKey,
              today: today,
              onJump: onJump,
              onOpenTags: onOpenTags,
            ),
            Expanded(
              child: width >= threeColumnWidth
                  ? _columns([_timed(timed), _tasks(untimed), _note()])
                  : width >= twoColumnWidth
                      ? _columns([
                          _stack([_timed(timed), _tasks(untimed)]),
                          _note(),
                        ])
                      : _stack([_timed(timed), _tasks(untimed), _note()]),
            ),
          ],
        );
      },
    );
  }

  Widget _timed(List<Task> timed) => TimedBlock(
        tasks: timed,
        tags: tags,
        shownDay: dayKey,
        onToggle: onToggle,
        onMenu: onMenu,
      );

  Widget _tasks(List<Task> untimed) => TasksBlock(
        tasks: untimed,
        tags: tags,
        shownDay: dayKey,
        onToggle: onToggle,
        onMenu: onMenu,
        onAdd: onAdd,
      );

  Widget _note() => NoteBlock(text: note, onChanged: onNoteChanged);

  /// Blocks one under another, the whole lot scrolling together.
  Widget _stack(List<Widget> blocks) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, block) in blocks.indexed) ...[
              if (i > 0) const SizedBox(height: 28),
              block,
            ],
          ],
        ),
      );

  /// Blocks side by side, each scrolling on its own.
  Widget _columns(List<Widget> blocks) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, block) in blocks.indexed)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(i == 0 ? 24 : 12, 0,
                    i == blocks.length - 1 ? 24 : 12, 32),
                child: block,
              ),
            ),
        ],
      );
}

/// The day page proper: swipe left and right through days, with everything
/// wired to Firestore.
class DayPage extends StatefulWidget {
  const DayPage({super.key, required this.repo});

  final SeedlingRepo repo;

  @override
  State<DayPage> createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  /// Page indexes are offsets from today around this anchor, so you can swipe
  /// years in either direction without the page list having ends.
  static const int _anchor = 500000;

  final String _today = todayKey();
  final PageController _controller = PageController(initialPage: _anchor);
  Timer? _noteDebounce;

  @override
  void dispose() {
    _noteDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _dayForPage(int index) => addDays(_today, index - _anchor);

  void _jumpTo(int deltaFromToday) => _controller.animateToPage(
        _anchor + deltaFromToday,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  /// Checking off records *this* day; unchecking only works on the day it was
  /// checked, so history stays where it happened.
  void _toggle(Task task, String day) {
    switch (checkStateOn(task, day)) {
      case TaskCheckState.open:
        widget.repo.setCompleted(task, day);
      case TaskCheckState.checkedHere:
        widget.repo.setCompleted(task, null);
      case TaskCheckState.doneLater:
        break;
    }
  }

  // ponytail: last write wins on the note — one person, one device at a time.
  void _saveNote(String day, String text) {
    _noteDebounce?.cancel();
    _noteDebounce = Timer(
      const Duration(milliseconds: 500),
      () => widget.repo.saveNote(day, text),
    );
  }

  Future<void> _openMenu(Task task) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Snooze to…'),
              onTap: () => Navigator.pop(context, 'snooze'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'delete') {
      await widget.repo.deleteTask(task);
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfKey(task.date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) await widget.repo.snooze(task, dayKeyOf(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Tag>>(
          stream: widget.repo.watchTags(),
          builder: (context, tagSnap) {
            final tags = {
              for (final tag in tagSnap.data ?? const <Tag>[]) tag.id: tag
            };
            return StreamBuilder<List<Task>>(
              stream: widget.repo.watchTasks(),
              builder: (context, taskSnap) {
                final all = taskSnap.data ?? const <Task>[];
                return PageView.builder(
                  controller: _controller,
                  itemBuilder: (context, index) {
                    final day = _dayForPage(index);
                    return StreamBuilder<String>(
                      stream: widget.repo.watchNote(day),
                      builder: (context, noteSnap) => DayView(
                        dayKey: day,
                        today: _today,
                        tasks: tasksForDay(all, day, _today),
                        tags: tags,
                        note: noteSnap.data ?? '',
                        onJump: _jumpTo,
                        onToggle: (task) => _toggle(task, day),
                        onMenu: _openMenu,
                        onAdd: (title, {tagId, time}) => widget.repo
                            .addTask(title, date: day, tagId: tagId, time: time),
                        onNoteChanged: (text) => _saveNote(day, text),
                        onOpenTags: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TagsScreen(repo: widget.repo),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
