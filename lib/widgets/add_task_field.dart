import 'package:flutter/material.dart';

import '../models/someday_item.dart';
import '../models/tag.dart';
import '../theme/seedling_theme.dart';
import 'tag_chip.dart';

/// The line at the bottom of the task list you type a new task into.
///
/// Shaped like a task tile with an empty ghost checkbox, so adding a task
/// looks like the row it is about to become. The tag and clock buttons set
/// those before you submit; both reset once the task is added.
class AddTaskField extends StatefulWidget {
  const AddTaskField({
    super.key,
    required this.onAdd,
    this.tags = const [],
    this.someday = const [],
    this.onPullSomeday,
  });

  final void Function(String title, {String? tagId, String? time}) onAdd;
  final List<Tag> tags;

  /// The someday list, best first. Only the top few are ever offered — picking
  /// from a long list is the thing this flow exists to avoid.
  final List<SomedayItem> someday;
  final void Function(SomedayItem)? onPullSomeday;

  /// How many someday items the picker offers at once.
  static const int somedayOffered = 5;

  @override
  State<AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<AddTaskField> {
  final _controller = TextEditingController();
  Tag? _tag;
  String? _time;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final title = raw.trim();
    if (title.isEmpty) return;
    widget.onAdd(title, tagId: _tag?.id, time: _time);
    _controller.clear();
    setState(() {
      _tag = null;
      _time = null;
    });
  }

  Future<void> _pickTag() async {
    if (widget.tags.isEmpty) return;
    final picked = await showModalBottomSheet<Tag?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_tag != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('No tag'),
                onTap: () => Navigator.pop(context, null),
              ),
            for (final tag in widget.tags)
              ListTile(
                leading:
                    Icon(TagChip.iconOf(tag), color: TagChip.colorOf(tag)),
                title: Text(tag.name),
                onTap: () => Navigator.pop(context, tag),
              ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _tag = picked);
  }

  Future<void> _pickSomeday() async {
    final offered =
        widget.someday.take(AddTaskField.somedayOffered).toList();
    if (offered.isEmpty) return;
    final picked = await showModalBottomSheet<SomedayItem>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in offered)
              ListTile(
                leading: const Icon(Icons.playlist_add_check),
                title: Text(item.title),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (picked != null) widget.onPullSomeday?.call(picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.faint, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _submit,
              textInputAction: TextInputAction.done,
              style: text.bodyLarge,
              decoration: InputDecoration.collapsed(
                hintText: 'Add a task…',
                hintStyle:
                    text.bodyLarge?.copyWith(color: colors.faint),
              ),
            ),
          ),
          if (_time != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(_time!,
                  style: text.labelMedium
                      ?.copyWith(color: colors.muted)),
            ),
          if (widget.someday.isNotEmpty && widget.onPullSomeday != null)
            _GhostButton(
              icon: Icons.playlist_add_check,
              active: false,
              tooltip: 'From someday',
              onTap: _pickSomeday,
            ),
          _GhostButton(
            icon: Icons.schedule,
            active: _time != null,
            tooltip: 'Set a time',
            onTap: _pickTime,
          ),
          if (_tag != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: TagChip(_tag!),
            )
          else
            _GhostButton(
              icon: Icons.label_outline,
              active: false,
              tooltip: 'Pick a tag',
              onTap: _pickTag,
            ),
          if (_tag != null)
            _GhostButton(
              icon: Icons.edit_outlined,
              active: true,
              tooltip: 'Change tag',
              onTap: _pickTag,
            ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          size: 20,
          color:
              active ? colors.muted : colors.faint,
        ),
      );
  }
}
