import 'package:flutter/material.dart';

import '../models/tag.dart';
import '../theme/seedling_icons.dart';
import '../theme/seedling_palette.dart';

/// A tag shown as a small tinted chip. Colours come from the e-ink-safe
/// palette, so a chip looks the same on the phone, the Mac and the BigMe.
class TagChip extends StatelessWidget {
  const TagChip(this.tag, {super.key});

  final Tag tag;

  static Color colorOf(Tag tag) =>
      SeedlingPalette.tagColors[tag.colorIndex % SeedlingPalette.tagColors.length];

  static IconData iconOf(Tag tag) => tagIcons[tag.iconIndex % tagIcons.length];

  @override
  Widget build(BuildContext context) {
    final color = colorOf(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconOf(tag), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
