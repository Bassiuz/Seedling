import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/mirror_doc_id.dart';

void main() {
  // The exact id that crashed the app on the iPhone.
  const eventKitId =
      '______NativeStorePersistentID_______:gregorian/2DFB19BE-B573-478D-B928-954EBE910110';

  test('a slash in an EventKit id never reaches the document path', () {
    expect(mirrorDocId(eventKitId), isNot(contains('/')));
  });

  test('the reserved __…__ shape is not produced', () {
    final id = mirrorDocId(eventKitId);

    expect(RegExp(r'^__.*__$').hasMatch(id), isFalse);
    expect(id, startsWith('e'), reason: 'prefixed so it cannot be reserved');
  });

  test('it is never a path segment Firestore rejects outright', () {
    for (final input in ['.', '..', '/', '', 'a/b/c']) {
      final id = mirrorDocId(input);
      expect(id, isNot('.'));
      expect(id, isNot('..'));
      expect(id, isNot(contains('/')));
      expect(id, isNotEmpty);
    }
  });

  test('the same event always lands on the same document', () {
    expect(mirrorDocId(eventKitId), mirrorDocId(eventKitId));
  });

  test('different events never collide', () {
    expect(mirrorDocId('event-a'), isNot(mirrorDocId('event-b')));
    // Ids differing only in a character the encoding must not drop.
    expect(mirrorDocId('a/b'), isNot(mirrorDocId('a-b')));
  });

  test('non-ascii ids survive', () {
    expect(mirrorDocId('afspraak-café-🚲'), isNot(contains('/')));
    expect(mirrorDocId('afspraak-café-🚲'), isNotEmpty);
  });
}
