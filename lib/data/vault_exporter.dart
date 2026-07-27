import 'dart:io';

import '../logic/markdown.dart';
import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../models/someday_item.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/week_review.dart';

/// Mirrors Seedling into a folder of Markdown files.
///
/// One-way and idempotent: files are rewritten from the data, never read back,
/// so pointing an agent (or Obsidian) at the folder is safe and nothing there
/// can corrupt the app. Desktop only — a phone has nowhere useful to put it.
class VaultExporter {
  const VaultExporter(this.root);

  /// The vault folder, e.g. `~/Seedling Vault`.
  final Directory root;

  static bool get supported => Platform.isMacOS || Platform.isLinux;

  /// The default location, or null where there is no home directory to use.
  static Directory? defaultRoot() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    return Directory('$home/Seedling Vault');
  }

  Future<File> _write(String relativePath, String contents) async {
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);
    return file.writeAsString(contents);
  }

  Future<void> writeDay({
    required String dayKey,
    required List<Task> tasks,
    required Map<String, Tag> tags,
    required String note,
    List<CalendarEvent> events = const [],
    List<DailyQuestion> questions = const [],
    Map<String, String> answers = const {},
  }) =>
      _write(
        dayPath(dayKey),
        dayMarkdown(
          dayKey: dayKey,
          tasks: tasks,
          tags: tags,
          note: note,
          events: events,
          questions: questions,
          answers: answers,
        ),
      );

  Future<void> writeReview(WeekReview review) =>
      _write(reviewPath(review.weekKey), reviewMarkdown(review));

  Future<void> writeTags(List<Tag> tags) =>
      _write('tags.md', tagsMarkdown(tags));

  /// Writes one file per project, including the untagged group, so a deleted
  /// project's list does not linger with the wrong name.
  Future<void> writeSomeday(
      List<SomedayItem> items, Map<String, Tag> tags) async {
    final grouped = <String?, List<SomedayItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.tagId, () => []).add(item);
    }
    for (final entry in grouped.entries) {
      await _write(
        somedayPath(tags[entry.key]),
        somedayMarkdown(tags[entry.key], entry.value),
      );
    }
  }
}
