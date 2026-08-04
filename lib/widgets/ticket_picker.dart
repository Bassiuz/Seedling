import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/jira_ref.dart';
import '../models/jira_ticket.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';
import 'block_frame.dart';

/// The list you pick a ticket from.
///
/// Recency does the sorting, because the ticket you touched an hour ago is the
/// one you are about to touch again. Everything is reachable without the
/// mouse: type to filter, arrow through what is left, enter to take it.
class TicketPicker extends StatefulWidget {
  const TicketPicker({
    super.key,
    required this.tickets,
    required this.title,
    this.defaultSite,
  });

  final List<JiraTicket> tickets;
  final String title;

  /// Lets a bare key typed into the filter become a ticket of its own.
  final String? defaultSite;

  @override
  State<TicketPicker> createState() => _TicketPickerState();
}

class _TicketPickerState extends State<TicketPicker> {
  String _filter = '';
  int _selected = 0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<JiraTicket> get _shown {
    final needle = _filter.trim().toLowerCase();
    return [
      for (final ticket in widget.tickets)
        if (needle.isEmpty ||
            ticket.key.toLowerCase().contains(needle) ||
            (ticket.summary ?? '').toLowerCase().contains(needle))
          ticket,
    ];
  }

  /// What you typed, if it is a ticket Seedling does not know yet. A pasted
  /// link or a key you have never used should not mean going somewhere else
  /// to add it first.
  JiraTicket? get _typedTicket {
    final ref = parseJiraRef(_filter, defaultSite: widget.defaultSite);
    if (ref == null) return null;
    if (widget.tickets.any((t) => t.key == ref.key)) return null;
    return JiraTicket(key: ref.key, site: ref.site);
  }

  List<JiraTicket> get _rows {
    final typed = _typedTicket;
    return [?typed, ..._shown];
  }

  void _move(int delta) {
    final rows = _rows;
    if (rows.isEmpty) return;
    setState(() => _selected = (_selected + delta).clamp(0, rows.length - 1));
    // 44 is a row; enough to keep the highlighted one on screen.
    _scroll.animateTo(
      (_selected * 44).clamp(0, _scroll.position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  void _take() {
    final rows = _rows;
    if (_selected < rows.length) Navigator.pop(context, rows[_selected]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _take();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.pop(context);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final rows = _rows;
    final typed = _typedTicket;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  Focus(
                    onKeyEvent: _onKey,
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() {
                        _filter = value;
                        _selected = 0;
                      }),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Filter, or paste a link…',
                        hintStyle:
                            text.bodyLarge?.copyWith(color: colors.faint),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: rows.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyNote('Nothing matches'),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      shrinkWrap: true,
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _TicketRow(
                        ticket: rows[i],
                        selected: i == _selected,
                        isNew: typed != null && i == 0,
                        onTap: () => Navigator.pop(context, rows[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.ticket,
    required this.selected,
    required this.isNew,
    required this.onTap,
  });

  final JiraTicket ticket;
  final bool selected;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Not a ListTile: its ink and background are painted on the nearest
      // Material, which a coloured box above it would hide.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        color: selected ? colors.rule : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                ticket.key,
                style: text.labelSmall?.copyWith(
                  color: SeedlingPalette.azure,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                isNew ? 'Use this ticket' : ticket.summary ?? ticket.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: isNew ? colors.muted : colors.ink,
                  fontStyle: isNew ? FontStyle.italic : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
