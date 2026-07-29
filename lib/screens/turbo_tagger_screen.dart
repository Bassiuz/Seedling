import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/jira_account.dart';
import '../data/jira_client.dart';
import '../data/seedling_repo.dart';
import '../logic/day_key.dart';
import '../logic/duration_input.dart';
import '../logic/jira_keys.dart';
import '../logic/jira_usage.dart';
import '../logic/rollover.dart';
import '../models/jira_ticket.dart';
import '../models/task.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';
import '../widgets/time_sheet.dart';

/// One day's untagged work, and a ticket a tap away.
///
/// Only tasks with no ticket are listed: this screen exists to empty that
/// list, and a row that vanishes when you deal with it is the whole feeling
/// of the thing.
class TurboTaggerView extends StatelessWidget {
  const TurboTaggerView({
    super.key,
    required this.dayKey,
    required this.tasks,
    this.onDay,
    this.onTag,
    this.onImport,
    this.ticketCount = 0,
    this.status,
  });

  final String dayKey;

  /// Already filtered to the day, and to the ones without a ticket.
  final List<Task> tasks;

  /// Called with the number of days to move.
  final void Function(int delta)? onDay;
  final void Function(Task)? onTag;
  final VoidCallback? onImport;

  /// How many tickets are in the list to choose from.
  final int ticketCount;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const Expanded(child: BackLine()),
                    IconButton(
                      tooltip: 'Paste in some tickets',
                      onPressed: onImport,
                      icon: Icon(Icons.playlist_add, color: colors.muted),
                    ),
                  ],
                ),
                Text('Turbo tagger', style: text.displaySmall),
                const SizedBox(height: 6),
                Text(
                  ticketCount == 0
                      ? 'No tickets to choose from yet — paste a few in with '
                          'the button above.'
                      : '$ticketCount tickets, most recently used first.',
                  style: text.labelMedium,
                ),
                const SizedBox(height: 20),
                _DayBar(dayKey: dayKey, onDay: onDay),
                const SizedBox(height: 20),
                BlockFrame(
                  title: 'Needs a ticket',
                  icon: Icons.label_off_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (tasks.isEmpty)
                        const EmptyNote('Everything on this day is tagged')
                      else
                        for (final task in tasks)
                          _Row(task: task, onTag: onTag),
                    ],
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 16),
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

class _DayBar extends StatelessWidget {
  const _DayBar({required this.dayKey, this.onDay});

  final String dayKey;
  final void Function(int)? onDay;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton(
          tooltip: 'The day before',
          onPressed: onDay == null ? null : () => onDay!(-1),
          icon: Icon(Icons.chevron_left, color: colors.muted),
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('EEEE, MMMM d', 'en_US').format(dateOfKey(dayKey)),
              style: text.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'The day after',
          onPressed: onDay == null ? null : () => onDay!(1),
          icon: Icon(Icons.chevron_right, color: colors.muted),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.task, this.onTag});

  final Task task;
  final void Function(Task)? onTag;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final logged = task.minutesOn(task.date);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTag == null ? null : () => onTag!(task),
      title: Text(task.title, style: text.bodyLarge),
      subtitle: logged == 0
          ? null
          : Text(TimeSheet.format(logged), style: text.labelSmall),
      trailing: Icon(Icons.add_link, color: colors.muted),
    );
  }
}

/// The list you pick from. Recency does the sorting, because the ticket you
/// touched an hour ago is the one you are about to touch again.
class TicketPicker extends StatefulWidget {
  const TicketPicker({super.key, required this.tickets, required this.title});

  final List<JiraTicket> tickets;
  final String title;

  @override
  State<TicketPicker> createState() => _TicketPickerState();
}

class _TicketPickerState extends State<TicketPicker> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final needle = _filter.trim().toLowerCase();
    final shown = [
      for (final ticket in widget.tickets)
        if (needle.isEmpty ||
            ticket.key.toLowerCase().contains(needle) ||
            (ticket.summary ?? '').toLowerCase().contains(needle))
          ticket,
    ];

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => _filter = value),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Filter…',
                      hintStyle:
                          text.bodyLarge?.copyWith(color: colors.faint),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: shown.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyNote('Nothing matches'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final ticket = shown[i];
                        return ListTile(
                          dense: true,
                          title: Text(ticket.summary ?? ticket.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium),
                          leading: SizedBox(
                            width: 72,
                            child: Text(
                              ticket.key,
                              style: text.labelSmall?.copyWith(
                                color: SeedlingPalette.azure,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.pop(context, ticket),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The live screen.
class TurboTaggerScreen extends StatefulWidget {
  const TurboTaggerScreen({
    super.key,
    required this.repo,
    required this.today,
    this.account,
    this.clientFor,
  });

  final SeedlingRepo repo;
  final String today;

  /// Overridable so tests never touch a keychain or the network.
  final JiraAccount? account;
  final JiraClient Function(String site, String email, String token)? clientFor;

  @override
  State<TurboTaggerScreen> createState() => _TurboTaggerScreenState();
}

class _TurboTaggerScreenState extends State<TurboTaggerScreen> {
  late final JiraAccount _account = widget.account ?? JiraAccount.standard();
  late String _day = widget.today;
  String? _status;
  bool _catchingUp = false;

  @override
  void initState() {
    super.initState();
    _catchUp();
  }

  /// Two things the list would otherwise be missing: every ticket you have
  /// already used somewhere in the app, and the names of the ones nobody has
  /// looked up yet.
  ///
  /// Done on opening rather than behind a button — a list of bare keys is not
  /// a list you can pick from, and you should not have to know that.
  Future<void> _catchUp() async {
    if (_catchingUp) return;
    _catchingUp = true;
    try {
      final used = ticketsInUse(
        tasks: await widget.repo.watchTasks().first,
        topics: await widget.repo.watchTopics().first,
        events: await widget.repo.watchEventExtras().first,
      );
      final known = await widget.repo.watchJiraTickets().first;
      final byKey = {for (final ticket in known) ticket.key: ticket};

      // Only what is new: rememberJiraTickets merges, but writing every
      // ticket on every open is a write per ticket per open.
      final fresh = [
        for (final ticket in used)
          if (!byKey.containsKey(ticket.key)) ticket,
      ];
      if (fresh.isNotEmpty) await widget.repo.rememberJiraTickets(fresh);

      final nameless = [
        for (final ticket in [...known, ...fresh])
          if (ticket.summary == null || ticket.summary!.isEmpty) ticket,
      ];
      if (nameless.isEmpty) return;
      await _fillNames(nameless);
    } finally {
      _catchingUp = false;
    }
  }

  /// Asks Jira what the nameless ones are called, a site at a time.
  Future<void> _fillNames(List<JiraTicket> nameless) async {
    final bySite = <String, List<JiraTicket>>{};
    for (final ticket in nameless) {
      if (ticket.site.isEmpty) continue;
      bySite.putIfAbsent(ticket.site, () => []).add(ticket);
    }

    var named = 0;
    for (final entry in bySite.entries) {
      for (final batch in inBatches([for (final t in entry.value) t.key])) {
        final found = await _lookUp(entry.key, batch);
        if (found == null) return;
        final learned = [
          for (final key in batch)
            if (found[key] != null && found[key]!.isNotEmpty)
              JiraTicket(key: key, site: entry.key, summary: found[key]),
        ];
        if (learned.isNotEmpty) {
          await widget.repo.rememberJiraTickets(learned);
          named += learned.length;
        }
      }
    }
    if (mounted && named > 0) {
      setState(() => _status = 'Looked up $named ticket names.');
    }
  }

  /// Paste anything. Whatever looks like a key is looked up, and whatever
  /// Jira does not recognise is quietly dropped.
  Future<void> _import() async {
    var pasted = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste in some tickets'),
        content: TextFormField(
          autofocus: true,
          maxLines: 6,
          minLines: 3,
          onChanged: (value) => pasted = value,
          decoration: const InputDecoration(
            hintText: 'AT-1234, links, a whole standup note…',
            helperText: 'Any format. Seedling picks the keys out and asks '
                'Jira what they are called.',
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final keys = parseJiraKeys(pasted);
    if (keys.isEmpty) {
      setState(() => _status = 'No ticket keys in that.');
      return;
    }

    final site = siteInText(pasted) ?? await widget.repo.watchJiraSite().first;
    if (site == null) {
      setState(() => _status =
          'Paste a full ticket link once, so Seedling learns your Jira '
          'address.');
      return;
    }
    if (siteInText(pasted) != null) {
      await widget.repo.rememberJiraSite(site);
    }

    setState(() => _status = 'Looking up ${keys.length}…');
    final found = await _lookUp(site, keys);

    // Without an account we cannot check them, so take them at face value
    // rather than losing the paste.
    final tickets = [
      for (final key in keys)
        if (found == null || found.containsKey(key))
          JiraTicket(key: key, site: site, summary: found?[key]),
    ];
    await widget.repo.rememberJiraTickets(tickets);

    if (!mounted) return;
    setState(() => _status = found == null
        ? 'Added ${tickets.length} without names — connect Jira on the '
            'timesheet to have them looked up.'
        : 'Added ${tickets.length} of ${keys.length}.');
  }

  /// Null when there is no account to ask with.
  Future<Map<String, String>?> _lookUp(String site, List<String> keys) async {
    final credentials = await _account.read();
    if (credentials == null) return null;
    final client = widget.clientFor?.call(site, credentials.email,
            credentials.token) ??
        JiraClient(
            site: site,
            email: credentials.email,
            apiToken: credentials.token);
    try {
      return await client.summaries(keys);
    } catch (error) {
      if (mounted) {
        setState(() => _status =
            error is JiraException ? error.message : 'Jira said no.');
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// Pick a ticket, then say how long it took. An hour is offered because it
  /// is the answer most of the time and a wrong hour you can see beats a
  /// blank you have to remember.
  Future<void> _tag(Task task, List<JiraTicket> tickets) async {
    if (tickets.isEmpty) {
      setState(() => _status = 'Paste some tickets in first.');
      return;
    }
    final ticket = await showModalBottomSheet<JiraTicket>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TicketPicker(tickets: tickets, title: task.title),
    );
    if (ticket == null || !mounted) return;

    await widget.repo.setJira(task, ticket.ref);
    await widget.repo.touchJiraTicket(ticket.ref, DateTime.now());
    if (!mounted) return;

    final minutes = await _askMinutes(task, ticket);
    if (minutes != null && minutes > 0) {
      await widget.repo.setTimeLogged(task, _day, minutes);
    }
    if (mounted) {
      setState(() => _status = '${task.title} → ${ticket.key}');
    }
  }

  Future<int?> _askMinutes(Task task, JiraTicket ticket) async {
    var entered = '1:00';
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${ticket.key} · how long?'),
        content: TextFormField(
          initialValue: entered,
          autofocus: true,
          onChanged: (value) => entered = value,
          onFieldSubmitted: (value) =>
              Navigator.pop(dialogContext, parseDuration(value)),
          decoration: const InputDecoration(
            helperText: 'Under 15 counts as hours, from 15 up as minutes.',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No time'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, parseDuration(entered)),
            child: const Text('Log it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JiraTicket>>(
      stream: widget.repo.watchJiraTickets(),
      builder: (context, ticketSnap) {
        final tickets = ticketSnap.data ?? const <JiraTicket>[];
        return StreamBuilder<List<Task>>(
          stream: widget.repo.watchTasks(),
          builder: (context, taskSnap) {
            final untagged = [
              for (final task
                  in tasksForDay(taskSnap.data ?? const [], _day, widget.today))
                if (task.jira == null) task,
            ];
            return TurboTaggerView(
              dayKey: _day,
              tasks: untagged,
              ticketCount: tickets.length,
              status: _status,
              onDay: (delta) => setState(() {
                _day = addDays(_day, delta);
                _status = null;
              }),
              onImport: _import,
              onTag: (task) => _tag(task, tickets),
            );
          },
        );
      },
    );
  }
}
