import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/seedling_repo.dart';

void main() {
  late SeedlingRepo repo;

  setUp(() => repo = SeedlingRepo(FakeFirebaseFirestore(), 'bas'));

  test('nothing used yet means an empty strip', () async {
    expect(await repo.watchRecentEmoji().first, isEmpty);
  });

  test('using emoji puts the newest first', () async {
    await repo.noteEmojiUsed('😄');
    await repo.noteEmojiUsed('🤔');

    expect(await repo.watchRecentEmoji().first, ['🤔', '😄']);
  });

  test('re-using one moves it up rather than duplicating it', () async {
    await repo.noteEmojiUsed('😄');
    await repo.noteEmojiUsed('🤔');
    await repo.noteEmojiUsed('😄');

    expect(await repo.watchRecentEmoji().first, ['😄', '🤔']);
  });

  test('only the last ten are kept', () async {
    // Twelve distinct single-cluster emoji: a keycap like "11️⃣" is two
    // clusters and would be trimmed to "1", which is not what is being tested.
    const used = [
      '😄', '🤔', '💻', '🚲', '🎯', '🦴', '🎰', '⏲️', '😢', '🌱', '📚', '🎧',
    ];
    for (final emoji in used) {
      await repo.noteEmojiUsed(emoji);
    }

    final recents = await repo.watchRecentEmoji().first;
    expect(recents, hasLength(10));
    expect(recents.first, '🎧', reason: 'newest first');
    expect(recents.contains('😄'), isFalse, reason: 'the oldest fell off');
    expect(recents.contains('🤔'), isFalse);
    expect(recents.last, '💻');
  });

  test('blank input is not recorded', () async {
    await repo.noteEmojiUsed('  ');

    expect(await repo.watchRecentEmoji().first, isEmpty);
  });

  test('one user does not see another user\'s emoji', () async {
    await repo.noteEmojiUsed('😄');

    final other = SeedlingRepo(FakeFirebaseFirestore(), 'someone-else');
    expect(await other.watchRecentEmoji().first, isEmpty);
  });
}
