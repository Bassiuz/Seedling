import 'package:flutter/material.dart';

import '../theme/seedling_palette.dart';

/// The line at the bottom of the task list you type a new task into.
///
/// Shaped like a task tile with an empty ghost checkbox, so adding a task
/// looks like the row it is about to become.
class AddTaskField extends StatefulWidget {
  const AddTaskField({super.key, required this.onAdd});

  final void Function(String title) onAdd;

  @override
  State<AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<AddTaskField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final title = raw.trim();
    if (title.isEmpty) return;
    widget.onAdd(title);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: SeedlingPalette.grayLight, width: 2),
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
                hintStyle: text.bodyLarge
                    ?.copyWith(color: SeedlingPalette.grayLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
