import 'package:flutter/material.dart';

import '../theme/seedling_palette.dart';

/// Shared chrome for the sections of a day page: a serif heading with a small
/// icon, a hairline under it, then the content.
///
/// Deliberately flat — no cards, no shadows. The page is one sheet of paper,
/// and elevation would break that on e-ink as much as on screen.
class BlockFrame extends StatelessWidget {
  const BlockFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: SeedlingPalette.grayDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: SeedlingPalette.paperLine),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// The grey one-liner a block shows when it has nothing in it.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: SeedlingPalette.grayLight),
        ),
      );
}
