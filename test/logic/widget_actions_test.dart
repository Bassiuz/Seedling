import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/widget_actions.dart';

void main() {
  group('the queue', () {
    test('starts empty and survives a round trip', () {
      final queued = PendingToggles.empty.plus('a').plus('b');

      expect(PendingToggles.parse(queued.toJson()).taskIds, ['a', 'b']);
    });

    test('a task tapped twice is queued once', () {
      // Two taps on a widget that has not redrawn yet is one intention.
      expect(PendingToggles.empty.plus('a').plus('a').taskIds, ['a']);
    });

    test('nothing stored reads as nothing queued', () {
      expect(PendingToggles.parse(null).isEmpty, isTrue);
      expect(PendingToggles.parse('').isEmpty, isTrue);
    });

    test('a corrupted store does not stop the app starting', () {
      expect(PendingToggles.parse('not json').isEmpty, isTrue);
      expect(PendingToggles.parse('{"a":1}').isEmpty, isTrue);
    });

    test('junk inside a valid list is dropped, the rest kept', () {
      expect(PendingToggles.parse('["a", 7, "", null, "b"]').taskIds,
          ['a', 'b']);
    });
  });

  group('the widget URI', () {
    test('carries the task that was tapped', () {
      expect(toggledTaskId(Uri.parse('seedling://toggle?id=abc123')), 'abc123');
    });

    test('an id with awkward characters survives', () {
      expect(toggledTaskId(Uri.parse('seedling://toggle?id=a%2Fb')), 'a/b');
    });

    test('anything else is not a toggle', () {
      expect(toggledTaskId(Uri.parse('seedling://open')), isNull);
      expect(toggledTaskId(Uri.parse('seedling://toggle')), isNull);
      expect(toggledTaskId(Uri.parse('seedling://toggle?id=')), isNull);
      expect(toggledTaskId(null), isNull);
    });
  });
}
