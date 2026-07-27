import 'package:flutter/material.dart';

import '../theme/seedling_palette.dart';
import 'block_frame.dart';

/// The free-form note for the day, written on ruled paper.
///
/// The note is stored as plain markdown and shown as plain text — no live
/// preview in this phase, so what you typed is exactly what you see.
class NoteBlock extends StatefulWidget {
  const NoteBlock({
    super.key,
    required this.text,
    required this.onChanged,
    this.minLines = 8,
  });

  final String text;
  final void Function(String) onChanged;
  final int minLines;

  /// Font size and line height are fixed here rather than taken from the theme
  /// because the ruled lines are drawn at exactly this spacing.
  static const double fontSize = 16;
  static const double lineHeight = 24;

  @override
  State<NoteBlock> createState() => _NoteBlockState();
}

class _NoteBlockState extends State<NoteBlock> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(NoteBlock old) {
    super.didUpdateWidget(old);
    // Only adopt text from outside when it genuinely differs, so a sync
    // arriving mid-sentence does not move the cursor.
    if (widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'SourceSans3',
      fontSize: NoteBlock.fontSize,
      height: NoteBlock.lineHeight / NoteBlock.fontSize,
      color: SeedlingPalette.ink,
    );

    return BlockFrame(
      title: 'Daily Note',
      icon: Icons.edit_outlined,
      child: CustomPaint(
        painter: const _RuledPaper(),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          maxLines: null,
          minLines: widget.minLines,
          style: style,
          cursorColor: SeedlingPalette.ink,
          decoration: const InputDecoration.collapsed(
            hintText: 'How was today?',
            hintStyle: TextStyle(
              fontFamily: 'SourceSans3',
              fontSize: NoteBlock.fontSize,
              height: NoteBlock.lineHeight / NoteBlock.fontSize,
              color: SeedlingPalette.grayLight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal rules at exactly one line of note text apart, so writing sits on
/// the lines instead of drifting away from them.
class _RuledPaper extends CustomPainter {
  const _RuledPaper();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SeedlingPalette.paperLine
      ..strokeWidth = 1;
    for (var y = NoteBlock.lineHeight; y <= size.height; y += NoteBlock.lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RuledPaper oldDelegate) => false;
}
