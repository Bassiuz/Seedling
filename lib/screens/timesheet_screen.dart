import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/jira_account.dart';
import '../data/jira_client.dart';
import '../data/seedling_repo.dart';
import '../logic/day_key.dart';
import '../logic/duration_input.dart';
import '../logic/jira_ref.dart';
import '../logic/timesheet.dart';
import '../logic/week_key.dart';
import '../logic/worklog.dart';
import '../models/event_extras.dart';
import '../models/task.dart';
import '../models/topic.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';

/// A week of logged time, as a grid, and the button that puts it in Jira.
///
/// Two grids: what you did, and what you always do. The second exists because
/// meetings and maintenance never become tasks, but they are most of some
/// weeks and the timesheet is wrong without them.
class TimesheetView extends StatelessWidget {
  const TimesheetView({
    super.key,
    required this.anyDay,
    required this.taskLines,
    required this.topicLines,
    this.onWeek,
    this.onEdit,
    this.onAddTopic,
    this.onEditTopic,
    this.onRemoveTopic,
    this.onSend,
    this.onSignIn,
    this.signedInAs,
    this.pending = 0,
    this.busy = false,
    this.status,
  });

  /// Any day in the week being shown.
  final String anyDay;
  final List<TimesheetRow> taskLines;
  final List<TimesheetRow> topicLines;

  /// Called with the number of weeks to move.
  final void Function(int delta)? onWeek;

  /// Sets a cell outright, in minutes.
  final void Function(TimesheetRow row, String dayKey, int minutes)? onEdit;

  final VoidCallback? onAddTopic;
  final void Function(Topic)? onEditTopic;
  final void Function(Topic)? onRemoveTopic;

  final VoidCallback? onSend;
  final VoidCallback? onSignIn;
  final String? signedInAs;

  /// How many worklogs this week is out of step by.
  final int pending;
  final bool busy;
  final String? status;

  static const double _labelWidth = 150;
  static const double _cellWidth = 52;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final days = weekDays(anyDay);
    final all = [...taskLines, ...topicLines];
    final totals = dayTotals(all);

    return Scaffold(
      body: SafeArea(
        // A timesheet is a narrow thing; stretched across a wide window the
        // arrows end up a foot apart from the week they move.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BackLine(),
            Text('Timesheet', style: text.displaySmall),
            const SizedBox(height: 12),
            _WeekBar(anyDay: anyDay, onWeek: onWeek),
            const SizedBox(height: 24),
            _Grid(
              days: days,
              blocks: [
                (
                  title: 'Tasks',
                  icon: Icons.check_circle_outline,
                  rows: taskLines,
                  empty: 'No ticketed work this week',
                  standing: false,
                ),
                (
                  title: 'Ongoing',
                  icon: Icons.autorenew,
                  rows: topicLines,
                  empty: 'Nothing standing yet',
                  standing: true,
                ),
              ],
              totals: totals,
              onEdit: onEdit,
              onAddTopic: onAddTopic,
              onEditTopic: onEditTopic,
              onRemoveTopic: onRemoveTopic,
            ),
            const SizedBox(height: 24),
            if (signedInAs == null)
              _Button(label: 'Connect Jira', onPressed: onSignIn)
            else ...[
              Text(
                pending == 0
                    ? 'Jira has this week already.'
                    : pending == 1
                        ? '1 worklog to send, as $signedInAs.'
                        : '$pending worklogs to send, as $signedInAs.',
                style: text.labelMedium?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 10),
              _Button(
                label: busy ? 'Sending…' : 'Send this week to Jira',
                onPressed: busy || pending == 0 ? null : onSend,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onSignIn,
                child: const Text('Use another account'),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: 12),
              Text(status!, style: text.labelMedium),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: SeedlingPalette.greenDeep,
        foregroundColor: colors.paper,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.anyDay, this.onWeek});

  final String anyDay;
  final void Function(int)? onWeek;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final monday = weekStartOf(anyDay);
    final sunday = weekEndOf(anyDay);
    final span = '${DateFormat('MMM d', 'en_US').format(dateOfKey(monday))} — '
        '${DateFormat('MMM d', 'en_US').format(dateOfKey(sunday))}';

    return Row(
      children: [
        IconButton(
          tooltip: 'The week before',
          onPressed: onWeek == null ? null : () => onWeek!(-1),
          icon: Icon(Icons.chevron_left, color: colors.muted),
        ),
        Expanded(
          child: Column(
            children: [
              Text(weekKeyOf(anyDay), style: text.titleMedium),
              Text(span, style: text.labelMedium),
            ],
          ),
        ),
        IconButton(
          tooltip: 'The week after',
          onPressed: onWeek == null ? null : () => onWeek!(1),
          icon: Icon(Icons.chevron_right, color: colors.muted),
        ),
      ],
    );
  }
}

typedef _Block = ({
  String title,
  IconData icon,
  List<TimesheetRow> rows,
  String empty,
  bool standing,
});

/// Both grids and the totals, sharing one horizontal scroll so the columns
/// stay lined up on a narrow screen.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.days,
    required this.blocks,
    required this.totals,
    this.onEdit,
    this.onAddTopic,
    this.onEditTopic,
    this.onRemoveTopic,
  });

  final List<String> days;
  final List<_Block> blocks;
  final List<int> totals;
  final void Function(TimesheetRow, String, int)? onEdit;
  final VoidCallback? onAddTopic;
  final void Function(Topic)? onEditTopic;
  final void Function(Topic)? onRemoveTopic;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    const width =
        TimesheetView._labelWidth + TimesheetView._cellWidth * 7 + 60;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final block in blocks) ...[
              BlockFrame(
                title: block.title,
                icon: block.icon,
                trailing: block.standing && onAddTopic != null
                    ? IconButton(
                        tooltip: 'Add something ongoing',
                        visualDensity: VisualDensity.compact,
                        onPressed: onAddTopic,
                        icon: Icon(Icons.add, color: colors.muted),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(days: days),
                    if (block.rows.isEmpty) EmptyNote(block.empty),
                    for (final row in block.rows)
                      _Row(
                        row: row,
                        days: days,
                        onEdit: onEdit,
                        onEditTopic: onEditTopic,
                        onRemoveTopic: onRemoveTopic,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: TimesheetView._labelWidth,
                    child: Text('Total', style: text.titleMedium),
                  ),
                  for (final minutes in totals)
                    SizedBox(
                      width: TimesheetView._cellWidth,
                      child: Center(
                        child: Text(
                          minutes == 0 ? '·' : _short(minutes),
                          style: text.labelMedium?.copyWith(
                            color: minutes == 0 ? colors.faint : colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Text(_short(totals.fold(0, (a, b) => a + b)),
                      style: text.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1:30" — a timesheet is read in columns, and "1h 30m" is too wide to line
/// seven of them up.
String _short(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.days});

  final List<String> days;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final today = todayKey();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: TimesheetView._labelWidth),
          for (final day in days)
            SizedBox(
              width: TimesheetView._cellWidth,
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE', 'en_US')
                        .format(dateOfKey(day))
                        .substring(0, 2),
                    style: text.labelSmall?.copyWith(
                      color: day == today ? colors.ink : colors.muted,
                      fontWeight: day == today ? FontWeight.w700 : null,
                    ),
                  ),
                  Text('${dateOfKey(day).day}',
                      style: text.labelSmall?.copyWith(color: colors.faint)),
                ],
              ),
            ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.days,
    this.onEdit,
    this.onEditTopic,
    this.onRemoveTopic,
  });

  final TimesheetRow row;
  final List<String> days;
  final void Function(TimesheetRow, String, int)? onEdit;
  final void Function(Topic)? onEditTopic;
  final void Function(Topic)? onRemoveTopic;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: TimesheetView._labelWidth,
            child: GestureDetector(
              onTap: row.topic == null || onEditTopic == null
                  ? null
                  : () => onEditTopic!(row.topic!),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium),
                  Text(
                    row.jira?.key ?? 'no ticket',
                    style: text.labelSmall?.copyWith(
                      color: row.jira == null
                          ? SeedlingPalette.crimson
                          : SeedlingPalette.azure,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (i, day) in days.indexed)
            _Cell(
              // Addressable, so a cell can be found by what it is rather
              // than by counting widgets.
              key: ValueKey('cell:${row.sourceId}@$day'),
              minutes: row.minutes[i],
              onSet: onEdit == null
                  ? null
                  : (minutes) => onEdit!(row, day, minutes),
              title: row.title,
              dayKey: day,
            ),
          SizedBox(
            width: 40,
            child: Text(
              row.total == 0 ? '' : _short(row.total),
              textAlign: TextAlign.right,
              style: text.labelMedium?.copyWith(color: colors.muted),
            ),
          ),
          if (row.topic != null && onRemoveTopic != null)
            SizedBox(
              width: 20,
              child: IconButton(
                tooltip: 'Remove',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => onRemoveTopic!(row.topic!),
                icon: Icon(Icons.close, size: 14, color: colors.faint),
              ),
            ),
        ],
      ),
    );
  }
}

/// One day of one row. Tap it and type: "2" is two hours, "45" is minutes,
/// same as everywhere else time is entered.
class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.minutes,
    required this.title,
    required this.dayKey,
    this.onSet,
  });

  final int minutes;
  final String title;
  final String dayKey;
  final void Function(int minutes)? onSet;

  Future<void> _edit(BuildContext context) async {
    var entered = minutes == 0 ? '' : _short(minutes);
    final typed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: TextFormField(
          initialValue: entered,
          autofocus: true,
          onChanged: (value) => entered = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
          decoration: InputDecoration(
            labelText:
                DateFormat('EEEE d MMMM', 'en_US').format(dateOfKey(dayKey)),
            helperText: 'Under 15 counts as hours, from 15 up as minutes. '
                'Empty clears it.',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, entered),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (typed == null) return;
    if (typed.trim().isEmpty) return onSet!(0);
    final parsed = parseDuration(typed);
    if (parsed != null) onSet!(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: TimesheetView._cellWidth,
      child: GestureDetector(
        onTap: onSet == null ? null : () => _edit(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: minutes == 0 ? colors.rule : colors.ink,
              width: minutes == 0 ? 1 : 1.5,
            ),
          ),
          child: Text(
            minutes == 0 ? '' : _short(minutes),
            style: text.labelMedium?.copyWith(
              color: colors.ink,
              fontWeight: minutes == 0 ? null : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// The live timesheet.
class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({
    super.key,
    required this.repo,
    this.account,
    this.clientFor,
  });

  final SeedlingRepo repo;

  /// Overridable so tests never touch a keychain.
  final JiraAccount? account;

  /// Overridable so tests never touch the network.
  final JiraClient Function(String site, String email, String token)? clientFor;

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  late final JiraAccount _account = widget.account ?? JiraAccount.standard();
  ({String email, String token})? _credentials;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final found = await _account.read();
    if (mounted) setState(() => _credentials = found);
  }

  Future<void> _connect() async {
    var address = _credentials?.email ?? '';
    var secret = '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Jira'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: address,
              autofocus: true,
              onChanged: (value) => address = value,
              decoration: const InputDecoration(labelText: 'Atlassian email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (value) => secret = value,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API token',
                helperText: 'From id.atlassian.com → Security → API tokens. '
                    'Kept in this device’s keychain, never in the cloud.',
                helperMaxLines: 3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    address = address.trim();
    secret = secret.trim();
    if (saved != true || address.isEmpty || secret.isEmpty) return;

    await _account.save(email: address, token: secret);
    await _loadAccount();
  }

  /// Records each worklog as soon as Jira accepts it, rather than at the end:
  /// a connection that drops halfway must not leave hours that are in Jira
  /// but not marked as sent, because the next press would log them again.
  Future<void> _send(List<WorklogAction> actions) async {
    final credentials = _credentials;
    if (credentials == null || actions.isEmpty) return;
    setState(() {
      _busy = true;
      _status = null;
    });

    final clients = <String, JiraClient>{};
    JiraClient clientFor(String site) => clients.putIfAbsent(
          site,
          () => widget.clientFor?.call(site, credentials.email,
                  credentials.token) ??
              JiraClient(
                site: site,
                email: credentials.email,
                apiToken: credentials.token,
              ),
        );

    var done = 0;
    String? failure;
    for (final action in actions) {
      try {
        final client = clientFor(action.jira.site);
        switch (action.verb) {
          case WorklogVerb.create:
            final id = await client.create(action);
            await widget.repo.recordSentWorklog(
                action.key, SentWorklog(id: id, minutes: action.minutes));
          case WorklogVerb.update:
            await client.update(action);
            await widget.repo.recordSentWorklog(action.key,
                SentWorklog(id: action.sentId!, minutes: action.minutes));
          case WorklogVerb.delete:
            await client.delete(action);
            await widget.repo.forgetSentWorklog(action.key);
        }
        done++;
      } catch (error) {
        failure = error is JiraException ? error.message : '$error';
        break;
      }
    }
    for (final client in clients.values) {
      client.close();
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = failure == null
          ? 'Sent $done to Jira.'
          : 'Sent $done, then stopped: $failure';
    });
  }

  /// Which week is on screen, as an offset from the one containing today.
  int _week = 0;

  String get _anyDay => addDays(weekStartOf(todayKey()), _week * 7);

  Future<void> _addTopic() => _editTopic(null);

  /// Name and ticket together: a standing row without a ticket has nowhere to
  /// send its hours, and is worth flagging rather than silently dropping.
  Future<void> _editTopic(Topic? existing) async {
    var name = existing?.title ?? '';
    var key = existing?.jira?.key ?? '';
    final site = await widget.repo.watchJiraSite().first;
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Something ongoing' : 'Edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              autofocus: true,
              onChanged: (value) => name = value,
              decoration: const InputDecoration(
                  labelText: 'Name', hintText: 'Meetings'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: key,
              onChanged: (value) => key = value,
              decoration: InputDecoration(
                labelText: 'Jira ticket',
                hintText: site == null ? 'Paste the ticket URL' : 'MAF-4319',
                helperText: site == null
                    ? 'The first time, paste a full link.'
                    : 'A key is enough, or paste a link.',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name = name.trim();
    key = key.trim();
    if (saved != true || name.isEmpty) return;

    final ref = key.isEmpty ? null : parseJiraRef(key, defaultSite: site);
    if (ref != null && ref.site != site) {
      await widget.repo.rememberJiraSite(ref.site);
    }
    await widget.repo.upsertTopic(Topic(
      id: existing?.id ??
          name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-'),
      title: name,
      jira: ref ?? existing?.jira,
      minutes: existing?.minutes ?? const {},
      sortOrder: existing?.sortOrder ?? DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> _remove(Topic topic) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${topic.title}?'),
        content: const Text(
            'The hours already sent to Jira stay there. This only takes the '
            'row off the timesheet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure == true) await widget.repo.deleteTopic(topic);
  }

  Future<void> _setCell(
      TimesheetRow row, String dayKey, int minutes, List<Task> tasks) async {
    final topic = row.topic;
    if (topic != null) {
      await widget.repo.setTopicMinutes(topic, dayKey, minutes);
      return;
    }
    final task = tasks.where((t) => t.id == row.sourceId).firstOrNull;
    if (task != null) {
      await widget.repo.setTimeLogged(task, dayKey, minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: widget.repo.watchTasks(),
      builder: (context, taskSnap) => StreamBuilder<List<Topic>>(
        stream: widget.repo.watchTopics(),
        builder: (context, topicSnap) =>
            StreamBuilder<Map<String, EventExtras>>(
          stream: widget.repo.watchEventExtras(),
          builder: (context, extraSnap) =>
              StreamBuilder<Map<String, SentWorklog>>(
            stream: widget.repo.watchSentWorklogs(),
            builder: (context, sentSnap) {
              final tasks = taskSnap.data ?? const <Task>[];
              final topics = topicSnap.data ?? const <Topic>[];
              final days = weekDays(_anyDay);
              // Only this week goes when you press send: the button says
              // "this week", and a button that quietly does more than it says
              // is a button you stop trusting.
              final actions = worklogActions(
                tasks: tasks,
                topics: topics,
                events: extraSnap.data ?? const {},
                sent: sentSnap.data ?? const {},
              ).where((a) => days.contains(a.dayKey)).toList();

              return TimesheetView(
                anyDay: _anyDay,
                taskLines: taskRows(tasks, _anyDay),
                topicLines: topicRows(topics, _anyDay),
                onWeek: (delta) => setState(() => _week += delta),
                onEdit: (row, day, minutes) =>
                    _setCell(row, day, minutes, tasks),
                onAddTopic: _addTopic,
                onEditTopic: _editTopic,
                onRemoveTopic: _remove,
                signedInAs: _credentials?.email,
                pending: actions.length,
                busy: _busy,
                status: _status,
                onSignIn: _connect,
                onSend: () => _send(actions),
              );
            },
          ),
        ),
      ),
    );
  }
}
