import 'package:flutter/material.dart';

import '../theme/seedling_theme.dart';

/// The way back from a pushed screen.
///
/// Deliberately not a Material `AppBar`: one would put a grey bar and a second
/// title above pages that already carry their own serif heading. This is just
/// the arrow, sitting where a back arrow is expected.
///
/// On the Mac there is no edge-swipe to fall back on, so without this a screen
/// is a dead end.
class BackLine extends StatelessWidget {
  const BackLine({super.key, this.onBack});

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = SeedlingColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.arrow_back, color: colors.muted),
      ),
    );
  }
}
