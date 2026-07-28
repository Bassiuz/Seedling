import 'package:flutter/material.dart';

import '../data/seedling_repo.dart';
import '../models/tag.dart';
import '../theme/seedling_icons.dart';
import '../theme/seedling_palette.dart';
import '../theme/seedling_theme.dart';
import '../widgets/back_line.dart';
import '../widgets/block_frame.dart';
import '../widgets/tag_chip.dart';

/// The tag list, without a repo behind it, so it can be golden-tested.
class TagsView extends StatelessWidget {
  const TagsView({
    super.key,
    required this.tags,
    required this.onEdit,
    required this.onAdd,
  });

  final List<Tag> tags;
  final void Function(Tag) onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const BackLine(),
            const SizedBox(height: 8),
            BlockFrame(
            title: 'Tags',
            icon: Icons.label_outline,
            trailing: IconButton(
              onPressed: onAdd,
              tooltip: 'New tag',
              icon: Icon(Icons.add, color: colors.muted),
            ),
            child: tags.isEmpty
                ? const EmptyNote('No tags yet')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final tag in tags)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(TagChip.iconOf(tag),
                              color: TagChip.colorOf(tag)),
                          title: Text(tag.name,
                              style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () => onEdit(tag),
                        ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name, colour and icon for one tag. Used for both new and existing tags.
class TagEditor extends StatefulWidget {
  const TagEditor({super.key, this.initial, required this.onSave});

  /// Null when creating a tag.
  final Tag? initial;
  final void Function(String name, int colorIndex, int iconIndex) onSave;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late int _colorIndex = widget.initial?.colorIndex ?? 0;
  late int _iconIndex = widget.initial?.iconIndex ?? 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    final color = SeedlingPalette.tagColors[_colorIndex];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.initial == null ? 'New tag' : 'Edit tag',
              style: text.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            style: text.bodyLarge,
            decoration: const InputDecoration.collapsed(hintText: 'Name'),
          ),
          const SizedBox(height: 20),
          Text('Colour', style: text.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < SeedlingPalette.tagColors.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SeedlingPalette.tagColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == _colorIndex
                            ? colors.ink
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Icon', style: text.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < tagIcons.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _iconIndex = i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == _iconIndex
                            ? color
                            : colors.rule,
                        width: 2,
                      ),
                    ),
                    child: Icon(tagIcons[i], size: 20, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final name = _name.text.trim();
              if (name.isEmpty) return;
              widget.onSave(name, _colorIndex, _iconIndex);
            },
            style: FilledButton.styleFrom(
              backgroundColor: SeedlingPalette.greenDeep,
              foregroundColor: colors.paper,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// The live tags screen.
class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key, required this.repo});

  final SeedlingRepo repo;

  /// A readable document id, so the Firestore console stays browsable. Editing
  /// keeps the original id, so a rename never orphans the tasks pointing at it.
  static String idFor(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');

  Future<void> _edit(
    BuildContext context, {
    Tag? existing,
    required int nextSortOrder,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => TagEditor(
        initial: existing,
        onSave: (name, colorIndex, iconIndex) {
          repo.upsertTag(Tag(
            id: existing?.id ?? idFor(name),
            name: name,
            colorIndex: colorIndex,
            iconIndex: iconIndex,
            sortOrder: existing?.sortOrder ?? nextSortOrder,
          ));
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tag>>(
      stream: repo.watchTags(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <Tag>[];
        return TagsView(
          tags: tags,
          onAdd: () => _edit(context, nextSortOrder: tags.length),
          onEdit: (tag) =>
              _edit(context, existing: tag, nextSortOrder: tags.length),
        );
      },
    );
  }
}
