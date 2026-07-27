import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/widgets/day_header.dart';

/// The label of the day shortcut currently drawn as selected, or null when the
/// shown day is none of the three.
String? selectedShortcutLabel(WidgetTester tester) {
  for (final label in ['Yesterday', 'Today', 'Tomorrow']) {
    final finder = find.ancestor(
      of: find.text(label),
      matching: find.byType(DayShortcut),
    );
    if (finder.evaluate().isEmpty) continue;
    if (tester.widget<DayShortcut>(finder).selected) return label;
  }
  return null;
}
