import 'package:flutter/material.dart';

import '../data/seedling_repo.dart';
import '../models/someday_item.dart';
import '../models/tag.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';
import '../widgets/tag_chip.dart';

/// The someday lists without a repo behind them, so they can be golden-tested.
///
/// Grouped by project, because "what could I do for Moxify" is the question
/// this list actually answers.
class SomedayView extends StatelessWidget {
  const SomedayView({
    super.key,
    required this.items,
    required this.tags,
    required this.onAdd,
    required this.onPromote,
    required this.onDelete,
  });

  final List<SomedayItem> items;
  final Map<String, Tag> tags;
  final void Function(String title, String? tagId) onAdd;
  final void Function(SomedayItem) onPromote;
  final void Function(SomedayItem) onDelete;

  /// Items grouped by tag id, each still in priority order. The untagged group
  /// is keyed by null and comes last.
  static Map<String?, List<SomedayItem>> group(List<SomedayItem> items) {
    final grouped = <String?, List<SomedayItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.tagId, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final grouped = group(items);
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return (tags[a]?.sortOrder ?? 0).compareTo(tags[b]?.sortOrder ?? 0);
      });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BackLine(),
            Text('Someday', style: text.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Ideas parked per project, best first. Pull one onto today from '
              'the add-task line.',
              style: text.labelMedium,
            ),
            const SizedBox(height: 24),
            if (items.isEmpty) const EmptyNote('Nothing parked yet'),
            // A tag can be deleted while items still point at it, so never
            // assume the lookup succeeds.
            for (final key in keys) ...[
              BlockFrame(
                title: tags[key]?.name ?? 'No project',
                icon: tags[key] == null
                    ? Icons.inbox_outlined
                    : TagChip.iconOf(tags[key]!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in grouped[key]!)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title, style: text.bodyLarge),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Do it today',
                              onPressed: () => onPromote(item),
                              icon: Icon(Icons.today_outlined,
                                  color: colors.muted),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => onDelete(item),
                              icon: Icon(Icons.delete_outline,
                                  color: colors.faint),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            _AddSomeday(tags: tags.values.toList(), onAdd: onAdd),
          ],
        ),
      ),
    );
  }
}

class _AddSomeday extends StatefulWidget {
  const _AddSomeday({required this.tags, required this.onAdd});

  final List<Tag> tags;
  final void Function(String title, String? tagId) onAdd;

  @override
  State<_AddSomeday> createState() => _AddSomedayState();
}

class _AddSomedayState extends State<_AddSomeday> {
  final _controller = TextEditingController();
  Tag? _tag;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final title = raw.trim();
    if (title.isEmpty) return;
    widget.onAdd(title, _tag?.id);
    _controller.clear();
    setState(() => _tag = null);
  }

  Future<void> _pickTag() async {
    if (widget.tags.isEmpty) return;
    final picked = await showModalBottomSheet<Tag?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('No project'),
              onTap: () => Navigator.pop(context, null),
            ),
            for (final tag in widget.tags)
              ListTile(
                leading: Icon(TagChip.iconOf(tag), color: TagChip.colorOf(tag)),
                title: Text(tag.name),
                onTap: () => Navigator.pop(context, tag),
              ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _tag = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.add, color: colors.faint),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: _submit,
            textInputAction: TextInputAction.done,
            style: text.bodyLarge,
            decoration: InputDecoration.collapsed(
              hintText: 'Park an idea…',
              hintStyle: text.bodyLarge?.copyWith(color: colors.faint),
            ),
          ),
        ),
        if (_tag != null) TagChip(_tag!),
        IconButton(
          tooltip: 'Pick a project',
          onPressed: _pickTag,
          icon: Icon(Icons.label_outline, color: colors.faint),
        ),
      ],
    );
  }
}

/// The live someday screen.
class SomedayScreen extends StatelessWidget {
  const SomedayScreen({super.key, required this.repo, required this.today});

  final SeedlingRepo repo;
  final String today;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tag>>(
      stream: repo.watchTags(),
      builder: (context, tagSnap) {
        final tags = {
          for (final tag in tagSnap.data ?? const <Tag>[]) tag.id: tag
        };
        return StreamBuilder<List<SomedayItem>>(
          stream: repo.watchSomeday(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <SomedayItem>[];
            return SomedayView(
              items: items,
              tags: tags,
              onAdd: (title, tagId) =>
                  repo.addSomeday(title, tagId: tagId, priority: items.length),
              onPromote: (item) => repo.promoteSomeday(item, today),
              onDelete: repo.deleteSomeday,
            );
          },
        );
      },
    );
  }
}
