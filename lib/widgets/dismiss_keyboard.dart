import 'package:flutter/material.dart';

/// Puts the keyboard away when you tap anything that is not itself
/// interactive. Wraps the whole app, so it applies on every screen.
///
/// Translucent hit testing: buttons, fields and list rows still receive their
/// taps first, and this only sees the ones nothing else wanted.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: child,
      );
}
