import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/seedling_repo.dart';
import '../data/calendar_source.dart';
import '../data/settings_store.dart';
import '../data/vault_mirror.dart';
import '../data/vault_service.dart';
import '../data/widget_publisher.dart';
import '../logic/day_key.dart';
import '../logic/event_time.dart';
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
import '../widgets/tag_chip.dart';
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
    this.onHideEvent,
    this.onUnhideEvent,
    this.onToggleEvent,
    this.doneEvents = const {},
    this.today,
    this.now,
  });

  /// Active questions for this day, and the answers given so far.
  final List<DailyQuestion> questions;
  final Map<String, String> answers;
  final void Function(DailyQuestion, String?)? onAnswer;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final List<CalendarEvent> events;
  final Set<String> hiddenKeys;
  final void Function(CalendarEvent)? onHideEvent;
  final void Function(CalendarEvent)? onUnhideEvent;
  final void Function(CalendarEvent, bool done)? onToggleEvent;
  final Set<String> doneEvents;

  /// Today's key and the current clock, so anything already past can be shown
  /// as overdue. Null in tests that do not care.
  final String? today;
  final String? now;

  /// Already filtered and sorted for this day by `tasksForDay`.
  final List<Task> tasks;
  final Map<String, Tag> tags;
  final String dayKey;
  final String note;
  final void Function(Task) onToggle;
  final void Function(Task) onMenu;
  final void Function(String title, {String? tagId, String? time}) onAdd;
  final void Function(String) onNoteChanged;

  /// Below this everything stacks; above it the two task lists sit side by
  /// side with the note underneath them.
  static const double twoColumnWidth = 600;

  @override
  Widget build(BuildContext context) {
    final timed = tasks.where((t) => t.isTimed).toList();
    final untimed = tasks.where((t) => !t.isTimed).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= twoColumnWidth) {
          return _wide(timed, untimed);
        }
        return _stack(
            [_timed(timed), _tasks(untimed), _questions(), _note()]);
      },
    );
  }

  /// Timed and untimed beside each other, the note full width below them.
  ///
  /// One scroll for the whole page rather than a column each: the note is the
  /// long thing, and it should have the width to be worth writing in.
  Widget _wide(List<Task> timed, List<Task> untimed) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _timed(timed)),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tasks(untimed),
                      const SizedBox(height: 28),
                      _questions(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _note(),
          ],
        ),
      );

  Widget _timed(List<Task> timed) => TimedBlock(
        tasks: timed,
        tags: tags,
        shownDay: dayKey,
        onToggle: onToggle,
        onMenu: onMenu,
        events: events,
        hiddenKeys: hiddenKeys,
        onHideEvent: onHideEvent,
        onUnhideEvent: onUnhideEvent,
        onToggleEvent: onToggleEvent,
        doneEvents: doneEvents,
        today: today,
        now: now,
        onAdd: onAdd,
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
    this.onToggleReveal,
    this.revealing = false,
    this.questions = const [],
    this.answers = const {},
    this.onAnswer,
    this.someday = const [],
    this.onPullSomeday,
    this.events = const [],
    this.hiddenKeys = const {},
    this.onHideEvent,
    this.onUnhideEvent,
    this.onToggleEvent,
    this.doneEvents = const {},
    this.now,
  });

  final List<DailyQuestion> questions;
  final Map<String, String> answers;
  final void Function(DailyQuestion, String?)? onAnswer;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final List<CalendarEvent> events;
  final Set<String> hiddenKeys;
  final void Function(CalendarEvent)? onHideEvent;
  final void Function(CalendarEvent)? onUnhideEvent;
  final void Function(CalendarEvent, bool done)? onToggleEvent;
  final Set<String> doneEvents;

  /// The current clock, so anything already past shows as overdue. Null in
  /// tests that do not care.
  final String? now;
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
  final VoidCallback? onToggleReveal;
  final bool revealing;

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
            onToggleReveal: onToggleReveal,
            revealing: revealing,
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
                    onHideEvent: onHideEvent,
              onUnhideEvent: onUnhideEvent,
              onToggleEvent: onToggleEvent,
              doneEvents: doneEvents,
              today: today,
              now: now,
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
    this.publishesCalendar = false,
  });

  final SeedlingRepo repo;

  /// Where appointments come from. Defaults to nothing so tests and the BigMe
  /// both work without a device calendar.
  final CalendarSource calendar;

  /// Whether what this device reads is shared with the others. Only the device
  /// that can actually see your calendar should publish.
  final bool publishesCalendar;

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

  /// The current HH:mm, ticked every minute so something becomes overdue while
  /// you are looking at it rather than only after a restart.
  String _now = clockOf(DateTime.now());
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = clockOf(DateTime.now());
      if (next != _now && mounted) setState(() => _now = next);
    });
  }

  /// A window around today rather than the whole calendar: paging years back
  /// should not mean reading years of appointments.
  Future<void> _loadEvents() async {
    final from = addDays(_today, -60);
    final to = addDays(_today, 60);

    List<CalendarEvent> events;
    try {
      events = await widget.calendar.eventsBetween(from, to);
    } catch (error) {
      // No calendar on this platform, or permission refused. The day still
      // works; it just has no appointments on it.
      debugPrint('Seedling: could not read the calendar: $error');
      return;
    }

    // Only the device that reads a real calendar shares it. Publishing from a
    // device that cannot see iCloud would replace what the phone sent.
    if (widget.publishesCalendar && events.isNotEmpty) {
      unawaited(_write(
        () => widget.repo.publishCalendarMirror(events, from: from, to: to),
        'share your calendar with your other devices',
      ));
    }

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
    _clock?.cancel();
    // Write whatever is still queued: leaving the page should not lose the
    // last sentence to the debounce.
    _mirror?.flush();
    _mirror?.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _dayForPage(int index) => addDays(_today, index - _anchor);

  final _widget = const WidgetPublisher();
  String? _lastPublished;

  /// Null where this machine has nowhere to keep a vault.
  late final VaultMirror? _mirror = () {
    final vault = defaultVault();
    return vault == null ? null : VaultMirror(vault);
  }();

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

  /// Keeps the Markdown vault in step with the day on screen. Only the visible
  /// day, because it is the only one whose note and answers are loaded.
  void _mirrorDay({
    required String day,
    required List<Task> tasks,
    required Map<String, Tag> tags,
    required String note,
    required List<DailyQuestion> questions,
    required Map<String, String> answers,
    required Set<String> hidden,
    required List<SomedayItem> someday,
  }) {
    final mirror = _mirror;
    if (mirror == null) return;
    if (widget.settings?.vaultMirroring == false) return;

    mirror.day(
      dayKey: day,
      tasks: tasks,
      tags: tags,
      note: note,
      events: visibleEvents(_events[day] ?? const [], hidden),
      questions: questions,
      answers: answers,
    );
    mirror.sidecars(tags: tags.values.toList(), someday: someday);
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
            canReadDeviceCalendar: DeviceCalendar.supported,
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

  /// The same list the add line offers, plus a way back to no tag at all.
  Future<void> _pickTagFor(Task task, Map<String, Tag> tags) async {
    if (tags.isEmpty) return;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.tagId != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('No tag'),
                // An empty string means "clear", since null means "cancelled".
                onTap: () => Navigator.pop(sheetContext, ''),
              ),
            for (final tag in tags.values)
              ListTile(
                leading: Icon(TagChip.iconOf(tag), color: TagChip.colorOf(tag)),
                title: Text(tag.name),
                onTap: () => Navigator.pop(sheetContext, tag.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _write(
      () => widget.repo.setTag(task, picked.isEmpty ? null : picked),
      'set that tag',
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

  /// Everything you can do to a task after it exists. Tag and time are here
  /// as well as on the add line, because they are just as often decided
  /// afterwards as while typing.
  Future<void> _openMenu(Task task, String day, Map<String, Tag> tags) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Log time'),
              onTap: () => Navigator.pop(context, 'log'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(task.isTimed ? 'Change time' : 'Set a time…'),
              subtitle: task.isTimed ? Text(task.time!) : null,
              onTap: () => Navigator.pop(context, 'time'),
            ),
            if (task.isTimed)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: const Text('Remove the time'),
                onTap: () => Navigator.pop(context, 'untime'),
              ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(task.tagId == null ? 'Set a tag…' : 'Change tag'),
              subtitle: task.tagId == null
                  ? null
                  : Text(tags[task.tagId]?.name ?? task.tagId!),
              onTap: () => Navigator.pop(context, 'tag'),
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

    if (action == 'log') {
      await _logTime(task, day);
      return;
    }

    if (action == 'untime') {
      await _write(() => widget.repo.setTime(task, null), 'remove that time');
      return;
    }

    if (action == 'time') {
      final picked = await showTimePicker(
        context: context,
        initialTime: task.isTimed
            ? TimeOfDay(
                hour: int.parse(task.time!.split(':').first),
                minute: int.parse(task.time!.split(':').last),
              )
            : TimeOfDay.now(),
      );
      if (picked == null) return;
      await _write(
        () => widget.repo.setTime(task, clockOf(DateTime(0, 1, 1,
            picked.hour, picked.minute))),
        'set that time',
      );
      return;
    }

    if (action == 'tag') {
      await _pickTagFor(task, tags);
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
                      onToggleReveal: _toggleReveal,
                      revealing: _revealing,
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
                          return StreamBuilder<Set<String>>(
                            stream: widget.repo.watchDoneEvents(day),
                            builder: (context, doneSnap) =>
                                StreamBuilder<Map<String, String>>(
                            stream: widget.repo.watchAnswers(day),
                            builder: (context, answerSnap) =>
                                StreamBuilder<String>(
                            stream: widget.repo.watchNote(day),
                            builder: (context, noteSnap) {
                              if (day == _dayForPage(_index)) {
                                _mirrorDay(
                                  day: day,
                                  tasks: tasksForDay(all, day, _today),
                                  tags: tags,
                                  note: noteSnap.data ?? '',
                                  questions: questions,
                                  answers: answerSnap.data ?? const {},
                                  hidden: hidden,
                                  someday: someday,
                                );
                              }
                              return DayContent(
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
                              onMenu: (task) => _openMenu(task, day, tags),
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
                              onHideEvent: (event) => _write(
                                () => widget.repo.hideEvent(event.hideKey),
                                'hide that event',
                              ),
                              onUnhideEvent: (event) => _write(
                                () => widget.repo.unhideEvent(event.hideKey),
                                'show that event again',
                              ),
                              onToggleEvent: (event, done) => _write(
                                () => widget.repo
                                    .setEventDone(day, event.id, done),
                                done ? 'tick that off' : 'untick that',
                              ),
                              doneEvents: doneSnap.data ?? const {},
                              today: _today,
                              now: _now,
                            );
                            },
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
