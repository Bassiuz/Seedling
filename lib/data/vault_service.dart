import 'dart:io';

import '../models/tag.dart';
import 'seedling_repo.dart';
import 'vault_exporter.dart';

/// Pulls everything out of Firestore once and mirrors it to the vault.
///
/// A full sweep rather than an incremental sync: the data is small, the write
/// is idempotent, and "export everything" is a promise that is easy to keep.
class VaultService {
  const VaultService(this.repo, this.exporter);

  final SeedlingRepo repo;
  final VaultExporter exporter;

  /// Returns how many files were written.
  Future<int> exportAll() async {
    final tasks = await repo.watchTasks().first;
    final tagList = await repo.watchTags().first;
    final questions = await repo.watchQuestions().first;
    final someday = await repo.watchSomeday().first;
    final weeks = await repo.watchReviewedWeeks().first;
    final tags = {for (final tag in tagList) tag.id: tag};

    var written = 0;

    // Every day that has anything on it: a task planned or finished there, or a
    // note. Days with nothing get no file rather than an empty one.
    final days = <String>{
      for (final task in tasks) ...[
        task.date,
        if (task.completedOnDate != null) task.completedOnDate!,
      ],
    };

    for (final day in days) {
      final note = await repo.watchNote(day).first;
      final answers = await repo.watchAnswers(day).first;
      final onDay = tasks.where((t) => t.date == day).toList();
      if (onDay.isEmpty && note.trim().isEmpty && answers.isEmpty) continue;
      await exporter.writeDay(
        dayKey: day,
        tasks: onDay,
        tags: tags,
        note: note,
        questions: questions,
        answers: answers,
      );
      written++;
    }

    for (final week in weeks) {
      final review = await repo.watchReview(week).first;
      if (review == null) continue;
      await exporter.writeReview(review);
      written++;
    }

    await exporter.writeTags(tagList);
    written++;

    if (someday.isNotEmpty) {
      await exporter.writeSomeday(someday, tags);
      written += _projectCount(someday, tags);
    }

    return written;
  }

  int _projectCount(List<dynamic> items, Map<String, Tag> tags) =>
      items.map((i) => (i as dynamic).tagId).toSet().length;
}

/// The vault Seedling writes to on this machine, or null where there is none.
VaultExporter? defaultVault() {
  if (!VaultExporter.supported) return null;
  final root = VaultExporter.defaultRoot();
  return root == null ? null : VaultExporter(root);
}

/// True when this machine can hold a vault at all.
bool get vaultAvailable => VaultExporter.supported && !Platform.isIOS;
