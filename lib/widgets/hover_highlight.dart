import 'package:flutter/material.dart';

import '../theme/seedling_theme.dart';

/// Washes a row faintly as the pointer crosses it.
///
/// The keyboard shortcuts act on whatever is under the pointer, so you have to
/// be able to see which row that is. Soft and slow enough not to flicker as
/// the mouse crosses a list, and absent entirely on a touch screen, where
/// there is no pointer and nothing to show.
class HoverHighlight extends StatefulWidget {
  const HoverHighlight({super.key, required this.child, this.onHover});

  final Widget child;
  final void Function(bool hovering)? onHover;

  @override
  State<HoverHighlight> createState() => _HoverHighlightState();
}

class _HoverHighlightState extends State<HoverHighlight> {
  bool _hovering = false;

  void _set(bool value) {
    if (_hovering == value) return;
    setState(() => _hovering = value);
    widget.onHover?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onHover == null) return widget.child;

    final colors = SeedlingColors.of(context);
    return MouseRegion(
      onEnter: (_) => _set(true),
      onExit: (_) => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovering ? colors.rule.withValues(alpha: 0.45) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.child,
      ),
    );
  }
}
