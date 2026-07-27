import 'package:flutter/material.dart';

import '../data/seedling_repo.dart';
import '../models/daily_question.dart';
import '../theme/seedling_theme.dart';
import '../widgets/block_frame.dart';

/// The question list without a repo behind it, so it can be golden-tested.
class QuestionsView extends StatelessWidget {
  const QuestionsView({
    super.key,
    required this.questions,
    required this.onEdit,
    required this.onAdd,
  });

  final List<DailyQuestion> questions;
  final void Function(DailyQuestion) onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            BlockFrame(
              title: 'Daily questions',
              icon: Icons.task_alt,
              trailing: IconButton(
                onPressed: onAdd,
                tooltip: 'New question',
                icon: Icon(Icons.add, color: colors.muted),
              ),
              child: questions.isEmpty
                  ? const EmptyNote('No questions yet')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final question in questions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: question.emoji == null
                                ? Icon(
                                    question.isCheck
                                        ? Icons.check_circle_outline
                                        : Icons.tune,
                                    color: colors.muted,
                                  )
                                : Text(question.emoji!,
                                    style: text.titleMedium),
                            title: Text(
                              question.label,
                              style: text.bodyLarge?.copyWith(
                                color:
                                    question.active ? colors.ink : colors.faint,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (!question.active) 'off',
                                if (question.isCheck)
                                  'check'
                                else
                                  question.options.join(' · '),
                              ].join(' — '),
                              style: text.labelMedium,
                            ),
                            onTap: () => onEdit(question),
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

/// Label, emoji, and either a plain check or a list of choices.
class QuestionEditor extends StatefulWidget {
  const QuestionEditor({
    super.key,
    this.initial,
    required this.onSave,
    this.onDelete,
  });

  final DailyQuestion? initial;
  final void Function(String label, String? emoji, List<String> options,
      bool active) onSave;
  final VoidCallback? onDelete;

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _emoji = TextEditingController(text: widget.initial?.emoji ?? '');

  /// Comma-separated, because typing "Home, OV, Bike" is faster than a
  /// chip-builder UI for something edited twice a year.
  late final _options =
      TextEditingController(text: widget.initial?.options.join(', ') ?? '');
  late bool _active = widget.initial?.active ?? true;

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    _options.dispose();
    super.dispose();
  }

  List<String> get _parsedOptions => _options.text
      .split(',')
      .map((o) => o.trim())
      .where((o) => o.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.initial == null ? 'New question' : 'Edit question',
              style: text.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            style: text.bodyLarge,
            decoration: const InputDecoration.collapsed(
                hintText: 'Question, e.g. Work travel'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emoji,
            style: text.bodyLarge,
            decoration:
                const InputDecoration.collapsed(hintText: 'Emoji (optional)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _options,
            style: text.bodyLarge,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration.collapsed(
              hintText: 'Choices, comma separated — leave empty for a check',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _parsedOptions.isEmpty
                ? 'A plain check'
                : 'Chips: ${_parsedOptions.join(' · ')}',
            style: text.labelMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            onChanged: (on) => setState(() => _active = on),
            title: Text('Ask this every day', style: text.bodyMedium),
            subtitle: Text('Turning it off keeps past answers',
                style: text.labelMedium),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final label = _label.text.trim();
              if (label.isEmpty) return;
              final emoji = _emoji.text.trim();
              widget.onSave(
                  label, emoji.isEmpty ? null : emoji, _parsedOptions, _active);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colors.ink,
              foregroundColor: colors.paper,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
          if (widget.onDelete != null)
            TextButton(
              onPressed: widget.onDelete,
              child: Text('Delete', style: text.labelLarge),
            ),
        ],
      ),
    );
  }
}

/// The live questions screen.
class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key, required this.repo});

  final SeedlingRepo repo;

  static String idFor(String label) =>
      label.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');

  Future<void> _edit(
    BuildContext context, {
    DailyQuestion? existing,
    required int nextSortOrder,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => QuestionEditor(
        initial: existing,
        onDelete: existing == null
            ? null
            : () {
                repo.deleteQuestion(existing);
                Navigator.pop(sheetContext);
              },
        onSave: (label, emoji, options, active) {
          repo.upsertQuestion(DailyQuestion(
            id: existing?.id ?? idFor(label),
            label: label,
            emoji: emoji,
            options: options,
            active: active,
            sortOrder: existing?.sortOrder ?? nextSortOrder,
          ));
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DailyQuestion>>(
      stream: repo.watchQuestions(),
      builder: (context, snapshot) {
        final questions = snapshot.data ?? const <DailyQuestion>[];
        return QuestionsView(
          questions: questions,
          onAdd: () => _edit(context, nextSortOrder: questions.length),
          onEdit: (q) =>
              _edit(context, existing: q, nextSortOrder: questions.length),
        );
      },
    );
  }
}
