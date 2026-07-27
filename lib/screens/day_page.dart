import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/seedling_repo.dart';
import '../data/calendar_source.dart';
import '../data/settings_store.dart';
import '../data/vault_service.dart';
import '../data/widget_publisher.dart';
import '../logic/day_key.dart';
import '../logic/blacklist.dart';
import '../logic/rollover.dart';
import '../logic/week_key.dart';
import '../logic/widget_payload.dart';
import '../models/tag.dart';
import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../models/someday_item.dart';
import '../models/task.dart';
import '../widgets/day_header.dart';
import '../widgets/note_block.dart';
import '../widgets/questions_block.dart';
import '../widgets/tasks_block.dart';
import '../widgets/time_sheet.dart';
import '../widgets/timed_block.dart';
import 'questions_screen.dart';
import 'settings_screen.dart';
import 'week_review_screen.dart';
import 'someday_screen.dart';
import 'tags_screen.dart';

/// The blocks of one day, laid out for whatever width they are given. This is
/// the part that slides when you page between days — the header above it stays
/// put.
class DayContent extends StatelessWidget {
  const DayContent({
    super.key,
    required this.dayKey,
    required this.tasks,
    required this.tags,
    required this.note,
    required this.onToggle,
    required this.onMenu,
    required this.onAdd,
    required this.onNoteChanged,
    this.questions = const [],
    this.answers = const {},
    this.onAnswer,
    this.someday = const [],
    this.onPullSomeday,
    this.events = const [],
    this.hiddenKeys = const {},
    this.revealing = false,
    this.onHideEvent,
    this.onUnhideEvent,
  });

  /// Active questions for this day, and the answers given so far.
  final List<DailyQuestion> questions;
  final Map<String, String> answers;
  final void Function(DailyQuestion, String?)? onAnswer;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final List<CalendarEvent> events;
  final Set<String> hiddenKeys;
  final bool revealing;
  final void Function(CalendarEvent)? onHideEvent;
  final void Function(CalendarEvent)? onUnhideEvent;

  /// Already filtered and sorted for this day by `tasksForDay`.
  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String dayKey;
  final String note;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;
  final void Function(String title, {String? tagId, String? time}) onAdd;
  final void Function(String) onNoteChanged;

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
        if (width >= threeColumnWidth) {
          return _columns([
            _timed(timed),
            _stack([_tasks(untimed), _questions()]),
            _note(),
          ]);
        }
        if (width >= twoColumnWidth) {
          return _columns([
            _stack([_timed(timed), _tasks(untimed), _questions()]),
            _note(),
          ]);
        }
        return _stack(
            [_timed(timed), _tasks(untimed), _questions(), _note()]);
      },
    );
  }

  Widget _timed(List<Task> timed) => TimedBlock(
        tasks: timed,
        tags: tags,
        shownDay: dayKey,
        onToggle: onToggle,
        onMenu: onMenu,
        events: events,
        hiddenKeys: hiddenKeys,
        revealing: revealing,
        onHideEvent: onHideEvent,
        onUnhideEvent: onUnhideEvent,
      );

  Widget _tasks(List<Task> untimed) => TasksBlock(
        tasks: untimed,
        tags: tags,
        shownDay: dayKey,
        onToggle: onToggle,
        onMenu: onMenu,
        onAdd: onAdd,
        someday: someday,
        onPullSomeday: onPullSomeday,
      );

  Widget _note() => NoteBlock(text: note, onChanged: onNoteChanged);

  Widget _questions() => QuestionsBlock(
        questions: questions,
        answers: answers,
        onAnswer: onAnswer ?? (_, _) {},
      );

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

/// A whole day: the pinned header with the content under it. Golden tests
/// render this, so every layout can be checked without Firebase.
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
    this.onOpenSettings,
    this.onOpenReview,
    this.reviewDue = false,
    this.questions = const [],
    this.answers = const {},
    this.onAnswer,
    this.someday = const [],
    this.onPullSomeday,
    this.events = const [],
    this.hiddenKeys = const {},
    this.revealing = false,
    this.onHideEvent,
    this.onUnhideEvent,
  });

  final List<DailyQuestion> questions;
  final Map<String, String> answers;
  final void Function(DailyQuestion, String?)? onAnswer;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final List<CalendarEvent> events;
  final Set<String> hiddenKeys;
  final bool revealing;
  final void Function(CalendarEvent)? onHideEvent;
  final void Function(CalendarEvent)? onUnhideEvent;
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
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenReview;
  final bool reviewDue;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayHeader(
            dayKey: dayKey,
            today: today,
            onJump: onJump,
            onOpenSettings: onOpenSettings,
            onOpenReview: onOpenReview,
            reviewDue: reviewDue,
          ),
          Expanded(
            child: DayContent(
              dayKey: dayKey,
              tasks: tasks,
              tags: tags,
              note: note,
              onToggle: onToggle,
              onMenu: onMenu,
              onAdd: onAdd,
              onNoteChanged: onNoteChanged,
              questions: questions,
              answers: answers,
              onAnswer: onAnswer,
              someday: someday,
              onPullSomeday: onPullSomeday,
              events: events,
              hiddenKeys: hiddenKeys,
              revealing: revealing,
              onHideEvent: onHideEvent,
              onUnhideEvent: onUnhideEvent,
            ),
          ),
        ],
      );
}

/// The day page proper: swipe left and right through days, with everything
/// wired to Firestore. The header does not move with the pages.
class DayPage extends StatefulWidget {
  const DayPage({
    super.key,
    required this.repo,
    this.settings,
    this.onSignOut,
    this.signedInAs,
    this.calendar = const NoCalendar(),
  });

  final SeedlingRepo repo;

  /// Where appointments come from. Defaults to nothing so tests and the BigMe
  /// both work without a device calendar.
  final CalendarSource calendar;

  /// Null in tests that only care about the day itself; the settings button is
  /// hidden when it is absent.
  final SettingsStore? settings;
  final Future<void> Function()? onSignOut;
  final String? signedInAs;

  @override
  State<DayPage> createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  /// Page indexes are offsets from today around this anchor, so you can swipe
  /// years in either direction without the page list having ends.
  static const int _anchor = 500000;

  final String _today = todayKey();
  final PageController _controller = PageController(initialPage: _anchor);

  /// Which page the header is describing. Kept in step with the PageView so
  /// the pinned header follows both swipes and shortcut taps.
  int _index = _anchor;
  Timer? _noteDebounce;

  /// Appointments for the days around today, keyed by day.
  Map<String, List<CalendarEvent>> _events = const {};

  /// While true, hidden events are drawn greyed so a wrong hide can be undone.
  bool _revealing = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// A window around today rather than the whole calendar: paging years back
  /// should not mean reading years of appointments.
  Future<void> _loadEvents() async {
    final events = await widget.calendar
        .eventsBetween(addDays(_today, -60), addDays(_today, 60));
    if (!mounted) return;
    final byDay = <String, List<CalendarEvent>>{};
    for (final event in events) {
      byDay.putIfAbsent(event.dayKey, () => []).add(event);
    }
    setState(() => _events = byDay);
  }

  @override
  void dispose() {
    _noteDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _dayForPage(int index) => addDays(_today, index - _anchor);

  final _widget = const WidgetPublisher();
  String? _lastPublished;

  /// Pushes today to the home-screen widget, but only when it actually changed
  /// — this runs inside build, and updating a widget is not free.
  void _publishWidget(
      List<Task> tasks, Map<String, Tag> tags, Set<String> hidden) {
    final payload = buildWidgetPayload(
      dayKey: _today,
      tasks: tasks,
      events: visibleEvents(_events[_today] ?? const [], hidden),
      tags: tags,
    );
    final json = payload.toJson();
    if (json == _lastPublished) return;
    _lastPublished = json;
    _widget.publish(payload);
  }

  /// Cmd-Shift-H on the Mac, the escape hatch from a hide you did not mean.
  void _toggleReveal() => setState(() => _revealing = !_revealing);

  void _jumpTo(int deltaFromToday) => _controller.animateToPage(
        _anchor + deltaFromToday,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  void _openReview(String day) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WeekReviewScreen(
            repo: widget.repo,
            weekKey: reviewWeekFor(day),
          ),
        ),
      );

  String? _exportStatus;

  Future<void> _exportVault(StateSetter refreshSheet) async {
    final vault = defaultVault();
    if (vault == null) return;
    refreshSheet(() => _exportStatus = 'Exporting…');
    try {
      final count = await VaultService(widget.repo, vault).exportAll();
      refreshSheet(() => _exportStatus = 'Wrote $count files');
    } catch (error) {
      refreshSheet(() => _exportStatus = 'Failed: $error');
    }
  }

  void _openSettings() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StatefulBuilder(
            builder: (context, refresh) => SettingsScreen(
            settings: widget.settings!,
            signedInAs: widget.signedInAs,
            onExportVault:
                defaultVault() == null ? null : () => _exportVault(refresh),
            vaultPath: defaultVault()?.root.path,
            exportStatus: _exportStatus,
            onSignOut: () async {
              Navigator.of(context).pop();
              await widget.onSignOut?.call();
            },
            onOpenTags: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TagsScreen(repo: widget.repo),
              ),
            ),
            onOpenQuestions: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => QuestionsScreen(repo: widget.repo),
              ),
            ),
            onOpenSomeday: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SomedayScreen(repo: widget.repo, today: _today),
              ),
            ),
            ),
          ),
        ),
      );

  /// Every write goes through here: a failure has to be visible, or a rejected
  /// save looks exactly like a successful one.
  Future<void> _write(Future<void> Function() action, String what) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not $what: $error')),
      );
    }
  }

  /// Checking off records *this* day; unchecking only works on the day it was
  /// checked, so history stays where it happened.
  void _toggle(Task task, String day) {
    switch (checkStateOn(task, day)) {
      case TaskCheckState.open:
        _write(() => widget.repo.setCompleted(task, day), 'check that off');
      case TaskCheckState.checkedHere:
        _write(() => widget.repo.setCompleted(task, null), 'uncheck that');
      case TaskCheckState.doneLater:
        break;
    }
  }

  // ponytail: last write wins on the note — one person, one device at a time.
  void _saveNote(String day, String text) {
    _noteDebounce?.cancel();
    _noteDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _write(() => widget.repo.saveNote(day, text), 'save the note'),
    );
  }

  /// Keeps the sheet open while you tap, so logging an hour is four taps
  /// rather than four round trips through the menu.
  Future<void> _logTime(Task task, String day) => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => StreamBuilder<List<Task>>(
          stream: widget.repo.watchTasks(),
          builder: (context, snapshot) {
            final latest = (snapshot.data ?? const <Task>[])
                .where((t) => t.id == task.id)
                .firstOrNull;
            if (latest == null) return const SizedBox.shrink();
            return TimeSheet(
              task: latest,
              dayKey: day,
              onChange: (delta) => _write(
                () => widget.repo.logTime(latest, day, delta),
                'log that time',
              ),
            );
          },
        ),
      );

  Future<void> _openMenu(Task task, String day) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Log time'),
              onTap: () => Navigator.pop(context, 'time'),
            ),
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

    if (action == 'time') {
      await _logTime(task, day);
      return;
    }

    if (action == 'delete') {
      await _write(() => widget.repo.deleteTask(task), 'delete that');
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfKey(task.date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      await _write(
          () => widget.repo.snooze(task, dayKeyOf(picked)), 'snooze that');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyH,
            meta: true, shift: true): _toggleReveal,
        const SingleActivator(LogicalKeyboardKey.keyH,
            control: true, shift: true): _toggleReveal,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Tag>>(
          stream: widget.repo.watchTags(),
          builder: (context, tagSnap) {
            final tags = {
              for (final tag in tagSnap.data ?? const <Tag>[]) tag.id: tag
            };
            return StreamBuilder<List<DailyQuestion>>(
              stream: widget.repo.watchQuestions(),
              builder: (context, questionSnap) {
                final questions = (questionSnap.data ?? const <DailyQuestion>[])
                    .where((q) => q.active)
                    .toList();
                return StreamBuilder<Set<String>>(
              stream: widget.repo.watchHiddenEvents(),
              builder: (context, hiddenSnap) {
                final hidden = hiddenSnap.data ?? const <String>{};
                return StreamBuilder<List<String>>(
              stream: widget.repo.watchReviewedWeeks(),
              builder: (context, reviewedSnap) {
                final reviewedWeeks = reviewedSnap.data ?? const <String>[];
                return StreamBuilder<List<SomedayItem>>(
              stream: widget.repo.watchSomeday(),
              builder: (context, somedaySnap) {
                final someday = somedaySnap.data ?? const <SomedayItem>[];
                return StreamBuilder<List<Task>>(
              stream: widget.repo.watchTasks(),
              builder: (context, taskSnap) {
                final all = taskSnap.data ?? const <Task>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DayHeader(
                      dayKey: _dayForPage(_index),
                      today: _today,
                      onJump: _jumpTo,
                      onOpenSettings:
                          widget.settings == null ? null : _openSettings,
                      onOpenReview: () => _openReview(_dayForPage(_index)),
                      reviewDue: isReviewDay(_dayForPage(_index)) &&
                          !reviewedWeeks
                              .contains(reviewWeekFor(_dayForPage(_index))),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        onPageChanged: (index) =>
                            setState(() => _index = index),
                        itemBuilder: (context, index) {
                          final day = _dayForPage(index);
                        if (day == _today) {
                          _publishWidget(
                              tasksForDay(all, day, _today), tags, hidden);
                        }
                          return StreamBuilder<Map<String, String>>(
                            stream: widget.repo.watchAnswers(day),
                            builder: (context, answerSnap) =>
                                StreamBuilder<String>(
                            stream: widget.repo.watchNote(day),
                            builder: (context, noteSnap) => DayContent(
                              questions: questions,
                              answers: answerSnap.data ?? const {},
                              onAnswer: (question, value) => _write(
                                () => widget.repo
                                    .setAnswer(day, question.id, value),
                                'save that answer',
                              ),
                              dayKey: day,
                              tasks: tasksForDay(all, day, _today),
                              tags: tags,
                              note: noteSnap.data ?? '',
                              onToggle: (task) => _toggle(task, day),
                              onMenu: (task) => _openMenu(task, day),
                              onAdd: (title, {tagId, time}) => _write(
                                () => widget.repo.addTask(title,
                                    date: day, tagId: tagId, time: time),
                                'add that task',
                              ),
                              onNoteChanged: (text) => _saveNote(day, text),
                              someday: someday,
                              onPullSomeday: (item) => _write(
                                () => widget.repo.promoteSomeday(item, day),
                                'move that onto this day',
                              ),
                              events: visibleEvents(
                                _events[day] ?? const [],
                                hidden,
                                reveal: _revealing,
                              ),
                              hiddenKeys: hidden,
                              revealing: _revealing,
                              onHideEvent: (event) => _write(
                                () => widget.repo.hideEvent(event.hideKey),
                                'hide that event',
                              ),
                              onUnhideEvent: (event) => _write(
                                () => widget.repo.unhideEvent(event.hideKey),
                                'show that event again',
                              ),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
              },
            );
              },
            );
              },
            );
              },
            );
          },
        ),
      ),
        ),
      ),
    );
  }
}
