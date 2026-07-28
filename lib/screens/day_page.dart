import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/seedling_repo.dart';
import '../data/calendar_source.dart';
import '../data/settings_store.dart';
import '../data/vault_mirror.dart';
import '../data/vault_service.dart';
import '../data/widget_publisher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/day_key.dart';
import '../logic/day_pages.dart';
import '../logic/jira_ref.dart';
import '../logic/event_time.dart';
import '../logic/blacklist.dart';
import '../logic/rollover.dart';
import '../logic/standup.dart';
import '../logic/week_key.dart';
import '../logic/widget_payload.dart';
import '../models/tag.dart';
import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../models/event_extras.dart';
import '../models/someday_item.dart';
import '../models/task.dart';
import '../models/week_review.dart';
import 'standup_screen.dart';
import '../widgets/day_header.dart';
import '../widgets/month_sheet.dart';
import '../widgets/note_block.dart';
import '../widgets/questions_block.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tasks_block.dart';
import '../widgets/time_sheet.dart';
import '../widgets/timed_block.dart';
import 'goals_screen.dart';
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
    this.onEventMenu,
    this.onUnhideEvent,
    this.onToggleEvent,
    this.doneEvents = const {},
    this.eventExtras = const {},
    this.today,
    this.now,
    this.onOpenJira,
  });

  /// Active questions for this day, and the answers given so far.
  final List<DailyQuestion> questions;
  final Map<String, String> answers;
  final void Function(DailyQuestion, String?)? onAnswer;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final List<CalendarEvent> events;
  final Set<String> hiddenKeys;
  final void Function(CalendarEvent)? onEventMenu;
  final void Function(CalendarEvent)? onUnhideEvent;
  final void Function(CalendarEvent, bool done)? onToggleEvent;
  final Set<String> doneEvents;

  /// Tag, ticket and logged time per appointment, keyed by hide key.
  final Map<String, EventExtras> eventExtras;

  /// Today's key and the current clock, so anything already past can be shown
  /// as overdue. Null in tests that do not care.
  final String? today;
  final String? now;
  final void Function(JiraRef)? onOpenJira;

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
        return _stack([_timed(timed), _tasks(untimed), _note()]);
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
                Expanded(child: _tasks(untimed)),
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
        onEventMenu: onEventMenu,
        onUnhideEvent: onUnhideEvent,
        onToggleEvent: onToggleEvent,
        doneEvents: doneEvents,
        eventExtras: eventExtras,
        today: today,
        now: now,
        onAdd: onAdd,
        onOpenJira: onOpenJira,
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
        onOpenJira: onOpenJira,
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
    this.onToggleReveal,
    this.revealing = false,
    this.questions = const [],
    this.answers = const {},
    this.onAnswer,
    this.someday = const [],
    this.onPullSomeday,
    this.events = const [],
    this.hiddenKeys = const {},
    this.onEventMenu,
    this.onUnhideEvent,
    this.onToggleEvent,
    this.doneEvents = const {},
    this.eventExtras = const {},
    this.now,
    this.onOpenSomeday,
    this.onOpenCalendar,
  });

  final VoidCallback? onOpenSomeday;
  final VoidCallback? onOpenCalendar;
  final List<DailyQuestion> questions;
  final Map<String, String> answers;
  final void Function(DailyQuestion, String?)? onAnswer;
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;
  final List<CalendarEvent> events;
  final Set<String> hiddenKeys;
  final void Function(CalendarEvent)? onEventMenu;
  final void Function(CalendarEvent)? onUnhideEvent;
  final void Function(CalendarEvent, bool done)? onToggleEvent;
  final Set<String> doneEvents;

  /// Tag, ticket and logged time per appointment, keyed by hide key.
  final Map<String, EventExtras> eventExtras;

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
  final VoidCallback? onToggleReveal;
  final bool revealing;

  Widget _questionsBlock() => QuestionsBlock(
        questions: questions,
        answers: answers,
        onAnswer: onAnswer ?? (_, _) {},
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Answered and folded shut, the day's check-offs are one line and
          // sit beside the date. Otherwise they are something to do, and
          // belong under the header at full width.
          if (questions.isNotEmpty &&
              QuestionsBlock.allAnswered(questions, answers))
            DayHeader(
              dayKey: dayKey,
              today: today,
              onJump: onJump,
              onOpenSettings: onOpenSettings,
              onToggleReveal: onToggleReveal,
              revealing: revealing,
              onOpenSomeday: onOpenSomeday,
              onOpenCalendar: onOpenCalendar,
              trailing: _questionsBlock(),
            )
          else ...[
            DayHeader(
              dayKey: dayKey,
              today: today,
              onJump: onJump,
              onOpenSettings: onOpenSettings,
              onToggleReveal: onToggleReveal,
              revealing: revealing,
              onOpenSomeday: onOpenSomeday,
              onOpenCalendar: onOpenCalendar,
            ),
            if (questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _questionsBlock(),
              ),
          ],
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
                    onEventMenu: onEventMenu,
              onUnhideEvent: onUnhideEvent,
              onToggleEvent: onToggleEvent,
              doneEvents: doneEvents,
              eventExtras: eventExtras,
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

  /// Page zero is the Monday of this week; every eighth page is a review.
  late final String _anchorMonday = weekStartOf(_today);
  late final PageController _controller =
      PageController(initialPage: _anchor + pageForDay(_anchorMonday, _today));

  /// Which page the header is describing. Kept in step with the PageView so
  /// the pinned header follows both swipes and shortcut taps.
  late int _index = _anchor + pageForDay(_anchorMonday, _today);
  Timer? _noteDebounce;

  /// Appointments for the days around today, keyed by day.
  Map<String, List<CalendarEvent>> _events = const {};

  /// While true, hidden events are drawn greyed so a wrong hide can be undone.
  bool _revealing = false;

  /// The current HH:mm, ticked every minute so something becomes overdue while
  /// you are looking at it rather than only after a restart.
  String _now = clockOf(DateTime.now());
  Timer? _clock;

  /// Tags, tickets and logged time on appointments, by hide key. Held here
  /// rather than in a StreamBuilder — one small collection, and the day page
  /// is nested deeply enough already.
  Map<String, EventExtras> _eventExtras = const {};
  StreamSubscription<Map<String, EventExtras>>? _extrasSub;

  /// Days with a note, an answer or a ticked appointment on them, for the
  /// month calendar. Task completions are folded in when it opens.
  Set<String> _activeDays = const {};

  /// The day's check-offs, opened by hand after they were all answered.
  bool _questionsOpen = false;
  StreamSubscription<Set<String>>? _activeSub;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _extrasSub = widget.repo.watchEventExtras().listen(
        (extras) => setState(() => _eventExtras = extras));
    _activeSub = widget.repo
        .watchActiveDays()
        .listen((days) => setState(() => _activeDays = days));
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
    _extrasSub?.cancel();
    _activeSub?.cancel();
    // Write whatever is still queued: leaving the page should not lose the
    // last sentence to the debounce.
    _mirror?.flush();
    _mirror?.dispose();
    _controller.dispose();
    super.dispose();
  }

  DayPageSlot _slotForPage(int index) =>
      pageContent(_anchorMonday, index - _anchor);

  /// The day a page shows. A review page names the Sunday it follows, so the
  /// header still says something true while you are on it.
  String _dayForPage(int index) {
    final slot = _slotForPage(index);
    if (slot.dayKey != null) return slot.dayKey!;
    return weekEndOf(addDays(_anchorMonday,
        7 * ((index - _anchor - 7) ~/ slotsPerWeek)));
  }

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

  /// The same, for the week review you are writing.
  void _mirrorReview(WeekReview review) {
    if (widget.settings?.vaultMirroring == false) return;
    _mirror?.review(review);
  }

  /// Cmd-Shift-H on the Mac, the escape hatch from a hide you did not mean.
  void _toggleReveal() => setState(() => _revealing = !_revealing);

  void _jumpTo(int deltaFromToday) =>
      _jumpToDay(addDays(_today, deltaFromToday));

  void _jumpToDay(String day) => _controller.animateToPage(
        _anchor + pageForDay(_anchorMonday, day),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  /// The month, pulled down over the day. A day is filled in when you did
  /// something on it — wrote, answered, or ticked anything off.
  Future<void> _openCalendar(String shownDay) async {
    final tasks = await widget.repo.watchTasks().first;
    if (!mounted) return;
    final picked = await MonthSheet.show(
      context,
      selected: shownDay,
      today: _today,
      activeDays: {
        ..._activeDays,
        for (final task in tasks)
          if (task.completedOnDate != null) task.completedOnDate!,
      },
    );
    if (picked != null && mounted) _jumpToDay(picked);
  }


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
                builder: (_) => TagsScreen(repo: widget.repo, today: _today),
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
            onOpenGoals: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GoalsScreen(repo: widget.repo),
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

  /// The pinned header. [title] and [subtitle] override the date, for the
  /// review pages, which are about a week rather than a day.
  Widget _headerWith({
    required String day,
    Widget? trailing,
    String? title,
    String? subtitle,
  }) =>
      DayHeader(
        dayKey: day,
        today: _today,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onJump: _jumpTo,
        onOpenSettings: widget.settings == null ? null : _openSettings,
        onToggleReveal: _toggleReveal,
        revealing: _revealing,
        onOpenSomeday: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SomedayScreen(repo: widget.repo, today: _today),
          ),
        ),
        onOpenCalendar: () => _openCalendar(day),
        onTripleTapDate: () => _openStandup(day),
      );

  /// Three taps on the date. Read-only on purpose: it is something to read
  /// out, not somewhere to tick things off while you are talking.
  Future<void> _openStandup(String day) async {
    final tasks = await widget.repo.watchTasks().first;
    final tagList = await widget.repo.watchTags().first;
    final hidden = await widget.repo.watchHiddenEvents().first;
    if (!mounted) return;

    // Hidden appointments stay hidden here too — the ones you blacklisted are
    // exactly the ones nobody wants read out.
    List<CalendarEvent> on(String key) =>
        visibleEvents(_events[key] ?? const [], hidden);

    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => StandupView(
        standup: standupFor(
          tasks,
          day,
          events: on(day),
          previousEvents: on(addDays(day, -1)),
        ),
        tags: {for (final tag in tagList) tag.id: tag},
      ),
    ));
  }

  /// The pinned header, with the daily check-offs beside the date once they
  /// have all been answered.
  Widget _header({
    required String day,
    required List<DailyQuestion> questions,
    required Map<String, String> answers,
  }) {
    final header = _headerWith(day: day);

    if (questions.isEmpty) return header;

    final block = QuestionsBlock(
      questions: questions,
      answers: answers,
      expanded: _questionsOpen,
      onExpandedChanged: (open) => setState(() => _questionsOpen = open),
      onAnswer: (question, value) => _write(
        () => widget.repo.setAnswer(day, question.id, value),
        'save that answer',
      ),
    );

    // Answered and folded shut, it is one quiet line and tucks in beside the
    // date. Otherwise it is either something to do or something being
    // changed, and it belongs in the flow of the day at full width.
    final folded =
        QuestionsBlock.allAnswered(questions, answers) && !_questionsOpen;

    if (folded) return _headerWith(day: day, trailing: block);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: block,
        ),
      ],
    );
  }

  /// An appointment's menu. Hiding is here rather than on the long press
  /// itself, which used to hide it outright with nothing to undo it.
  ///
  /// An appointment can carry a tag, a ticket and logged time just like a
  /// task, because an hour in a meeting is an hour spent. It cannot be
  /// snoozed, deleted or retimed — the calendar owns all three.
  Future<void> _openEventMenu(
    CalendarEvent event,
    String day,
    Set<String> hidden,
    Map<String, Tag> tags,
  ) async {
    final isHidden = hidden.contains(event.hideKey);
    final extras = _eventExtras[event.hideKey] ?? const EventExtras();
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Log time'),
                onTap: () => Navigator.pop(sheetContext, 'log'),
              ),
              ListTile(
                leading: const Icon(Icons.label_outline),
                title:
                    Text(extras.tagId == null ? 'Set a tag…' : 'Change tag'),
                subtitle: extras.tagId == null
                    ? null
                    : Text(tags[extras.tagId]?.name ?? extras.tagId!),
                onTap: () => Navigator.pop(sheetContext, 'tag'),
              ),
              ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(extras.jira == null
                    ? 'Link a Jira ticket…'
                    : 'Change the ticket'),
                subtitle:
                    extras.jira == null ? null : Text(extras.jira!.key),
                onTap: () => Navigator.pop(sheetContext, 'jira'),
              ),
              if (extras.jira != null)
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Unlink the ticket'),
                  onTap: () => Navigator.pop(sheetContext, 'unjira'),
                ),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: Text(isHidden ? 'Show this again' : 'Hide this'),
                subtitle: Text(
                  isHidden
                      ? 'It will appear on your days again.'
                      : event.recurringId == null
                          ? 'Hides this appointment. Your calendar is '
                              'untouched.'
                          : 'Hides every occurrence of it. Your calendar is '
                              'untouched.',
                ),
                onTap: () => Navigator.pop(sheetContext, 'hide'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'log') {
      await _logEventTime(event, day);
      return;
    }

    if (action == 'tag') {
      final picked = await _pickTag(current: extras.tagId, tags: tags);
      if (picked == null) return;
      await _saveExtras(
        event,
        picked.isEmpty
            ? extras.copyWith(clearTag: true)
            : extras.copyWith(tagId: picked),
        'set that tag',
      );
      return;
    }

    if (action == 'unjira') {
      await _saveExtras(
          event, extras.copyWith(clearJira: true), 'unlink that ticket');
      return;
    }

    if (action == 'jira') {
      final ref = await _askJira(current: extras.jira);
      if (ref == null) return;
      await _saveExtras(event, extras.copyWith(jira: ref), 'link that ticket');
      return;
    }

    await _write(
      () => isHidden
          ? widget.repo.unhideEvent(event.hideKey)
          : widget.repo.hideEvent(event.hideKey),
      isHidden ? 'show that event again' : 'hide that event',
    );
  }

  Future<void> _saveExtras(
          CalendarEvent event, EventExtras extras, String what) =>
      _write(() => widget.repo.setEventExtras(event.hideKey, extras), what);

  /// The same sheet tasks get. Reads back through [_eventExtras] so the
  /// stepper follows what has just been written.
  Future<void> _logEventTime(CalendarEvent event, String day) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StreamBuilder<Map<String, EventExtras>>(
          stream: widget.repo.watchEventExtras(),
          builder: (context, snapshot) {
            final extras =
                (snapshot.data ?? _eventExtras)[event.hideKey] ??
                    const EventExtras();
            return TimeSheet(
              title: event.title,
              minutes: extras.minutesOn(day),
              totalMinutes: extras.totalMinutes,
              onChange: (delta) => _saveExtras(
                event,
                extras.withMinutes(day, extras.minutesOn(day) + delta),
                'log that time',
              ),
              onSet: (minutes) => _saveExtras(
                event,
                extras.withMinutes(day, minutes),
                'log that time',
              ),
            );
          },
        ),
      );

  /// Paste a browse URL or type a bare key. The site is remembered from the
  /// first URL, so afterwards `MAF-1234` on its own is enough.
  ///
  /// Returns null when it was cancelled or unreadable; the caller decides
  /// what the ticket gets attached to.
  Future<JiraRef?> _askJira({JiraRef? current}) async {
    final site = await widget.repo.watchJiraSite().first;
    if (!mounted) return null;

    final controller = TextEditingController(text: current?.key ?? '');
    final typed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Jira ticket'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
          decoration: InputDecoration(
            hintText: site == null ? 'Paste the ticket URL' : 'MAF-1234',
            helperText: site == null
                ? 'The first time, paste a full link so Seedling learns your '
                    'Jira address.'
                : 'A key is enough, or paste a link.',
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || typed == null) return null;

    final ref = parseJiraRef(typed, defaultSite: site);
    if (ref == null) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(needsSiteFor(typed, defaultSite: site)
              ? 'Paste a full ticket link once, so Seedling learns your Jira '
                  'address.'
              : 'That does not look like a Jira ticket.'),
        ),
      );
      return null;
    }

    if (ref.site != site) await widget.repo.rememberJiraSite(ref.site);
    return ref;
  }

  Future<void> _linkJira(Task task) async {
    final ref = await _askJira(current: task.jira);
    if (ref == null) return;
    await _write(() => widget.repo.setJira(task, ref), 'link that ticket');
  }

  Future<void> _openJira(JiraRef ref) async {
    final uri = Uri.parse(ref.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open ${ref.url}')));
    }
  }

  /// The same list the add line offers, plus a way back to no tag at all.
  ///
  /// Returns null when it was dismissed and an empty string for "no tag",
  /// since null already means cancelled.
  Future<String?> _pickTag({
    required String? current,
    required Map<String, Tag> tags,
  }) async {
    if (tags.isEmpty) return null;
    return showModalBottomSheet<String?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('No tag'),
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
  }

  Future<void> _pickTagFor(Task task, Map<String, Tag> tags) async {
    final picked = await _pickTag(current: task.tagId, tags: tags);
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
        // So the sheet rides above the keyboard rather than under it.
        isScrollControlled: true,
        builder: (sheetContext) => StreamBuilder<List<Task>>(
          stream: widget.repo.watchTasks(),
          builder: (context, snapshot) {
            final latest = (snapshot.data ?? const <Task>[])
                .where((t) => t.id == task.id)
                .firstOrNull;
            if (latest == null) return const SizedBox.shrink();
            return TimeSheet(
              title: latest.title,
              minutes: latest.minutesOn(day),
              totalMinutes: latest.totalMinutes,
              onChange: (delta) => _write(
                () => widget.repo.logTime(latest, day, delta),
                'log that time',
              ),
              onSet: (minutes) => _write(
                () => widget.repo.setTimeLogged(latest, day, minutes),
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
      // The menu has outgrown a fixed sheet; let it scroll rather than clip.
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
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
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(task.jira == null
                  ? 'Link a Jira ticket…'
                  : 'Change the ticket'),
              subtitle:
                  task.jira == null ? null : Text(task.jira!.key),
              onTap: () => Navigator.pop(context, 'jira'),
            ),
            if (task.jira != null)
              ListTile(
                leading: const Icon(Icons.link_off),
                title: const Text('Unlink the ticket'),
                onTap: () => Navigator.pop(context, 'unjira'),
              ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Snooze to…'),
              onTap: () => Navigator.pop(context, 'snooze'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Back to someday'),
              subtitle: const Text('Off the calendar, onto the list'),
              onTap: () => Navigator.pop(context, 'someday'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
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

    if (action == 'unjira') {
      await _write(() => widget.repo.setJira(task, null), 'unlink that ticket');
      return;
    }

    if (action == 'jira') {
      await _linkJira(task);
      return;
    }

    if (action == 'someday') {
      await _write(() => widget.repo.demoteToSomeday(task),
          'move that back to someday');
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
                    // The header is pinned, and the daily check-offs sit
                    // beside it, so they need the shown day's answers up here
                    // rather than inside the sliding page.
                    if (_slotForPage(_index).isReview)
                      _headerWith(
                        day: _dayForPage(_index),
                        title: 'Week review',
                        subtitle: _slotForPage(_index).weekKey,
                      )
                    else
                      StreamBuilder<Map<String, String>>(
                        stream: widget.repo
                            .watchAnswers(_dayForPage(_index)),
                        builder: (context, headerAnswers) => _header(
                          day: _dayForPage(_index),
                          questions: questions,
                          answers: headerAnswers.data ?? const {},
                        ),
                      ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        onPageChanged: (index) =>
                            setState(() => _index = index),
                        itemBuilder: (context, index) {
                          final slot = _slotForPage(index);
                          // Every eighth page is the review of the week that
                          // just ended, sitting where you would write it.
                          if (slot.isReview) {
                            return WeekReviewScreen(
                              repo: widget.repo,
                              weekKey: slot.weekKey!,
                              showBack: false,
                              // The pinned header already says which week.
                              showTitle: false,
                              onReview: _mirrorReview,
                            );
                          }
                          final day = slot.dayKey!;
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
                              onOpenJira: _openJira,
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
                              onEventMenu: (event) =>
                                  _openEventMenu(event, day, hidden, tags),
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
                              eventExtras: _eventExtras,
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
