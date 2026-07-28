import 'package:characters/characters.dart';

/// How many emoji the quick strip remembers.
const int recentEmojiLimit = 10;

/// The recent list after using [used]: most recent first, no duplicates, and
/// never longer than [max].
///
/// Re-using one already in the list moves it to the front rather than adding a
/// second copy, which is what keeps the strip showing what you actually reach
/// for instead of what you reached for once.
List<String> promoteEmoji(
  List<String> recents,
  String used, {
  int max = recentEmojiLimit,
}) {
  final emoji = firstEmoji(used);
  if (emoji == null) return List.of(recents);
  return [emoji, ...recents.where((e) => e != emoji)].take(max).toList();
}

/// The first grapheme cluster of [raw], or null if there is nothing usable.
///
/// A cluster rather than a code unit, so a flag or a skin-toned emoji survives
/// as the one character it looks like. Typing more than one just keeps the
/// first — the strip is a row of single marks.
String? firstEmoji(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.characters.first;
}
