import 'dart:async';

import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../models/someday_item.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/week_review.dart';
import 'vault_exporter.dart';

/// Keeps the Markdown vault in step with the app as you type.
///
/// Only the day you are actually looking at gets rewritten, because that is the
/// only day whose note and answers are loaded — re-exporting everything on each
/// keystroke would mean a Firestore read per day per change. "Export everything
/// now" in settings still exists for a full backfill.
///
/// Writes are debounced and deduplicated: typing a sentence produces one file
/// write, and a rebuild that changed nothing produces none.
class VaultMirror {
  VaultMirror(
    this.exporter, {
    this.debounce = const Duration(seconds: 2),
  });

  final VaultExporter exporter;
  final Duration debounce;

  Timer? _dayTimer;
  Timer? _sidecarTimer;

  /// The last content written, so an identical rebuild is not written twice.
  final Map<String, String> _lastWritten = {};

  Future<void> Function()? _pendingDay;
  Future<void> Function()? _pendingSidecars;

  /// Number of writes actually performed. Handy in tests and for the status
  /// line in settings.
  int writes = 0;

  void dispose() {
    _dayTimer?.cancel();
    _sidecarTimer?.cancel();
  }

  /// Queues a rewrite of one day. Safe to call from build.
  void day({
    required String dayKey,
    required List<Task> tasks,
    required Map<String, Tag> tags,
    required String note,
    List<CalendarEvent> events = const [],
    List<DailyQuestion> questions = const [],
    Map<String, String> answers = const {},
  }) {
    // A cheap fingerprint of everything that ends up in the file. If it has not
    // moved, there is nothing to write.
    final signature = [
      dayKey,
      note,
      for (final t in tasks)
        '${t.id}|${t.title}|${t.time}|${t.tagId}|${t.completedOnDate}|${t.minutesOn(dayKey)}',
      for (final e in events) '${e.id}|${e.title}|${e.time}|${e.allDay}',
      for (final entry in answers.entries) '${entry.key}=${entry.value}',
      for (final tag in tags.values) '${tag.id}:${tag.name}',
    ].join('\n');

    if (_lastWritten['day:$dayKey'] == signature) return;
    _lastWritten['day:$dayKey'] = signature;

    _pendingDay = () => exporter.writeDay(
          dayKey: dayKey,
          tasks: tasks,
          tags: tags,
          note: note,
          events: events,
          questions: questions,
          answers: answers,
        );
    _dayTimer?.cancel();
    _dayTimer = Timer(debounce, () => _run(_pendingDay));
  }

  /// Queues a rewrite of the files that do not belong to a single day.
  void sidecars({
    required List<Tag> tags,
    required List<SomedayItem> someday,
    WeekReview? review,
  }) {
    final signature = [
      for (final tag in tags) '${tag.id}:${tag.name}:${tag.sortOrder}',
      for (final item in someday) '${item.id}:${item.title}:${item.tagId}',
      if (review != null) '${review.weekKey}:${review.toMap()}',
    ].join('\n');

    if (_lastWritten['sidecars'] == signature) return;
    _lastWritten['sidecars'] = signature;

    final byId = {for (final tag in tags) tag.id: tag};
    _pendingSidecars = () async {
      await exporter.writeTags(tags);
      if (someday.isNotEmpty) await exporter.writeSomeday(someday, byId);
      if (review != null) await exporter.writeReview(review);
    };
    _sidecarTimer?.cancel();
    _sidecarTimer = Timer(debounce, () => _run(_pendingSidecars));
  }

  Future<void> _run(Future<void> Function()? work) async {
    if (work == null) return;
    try {
      await work();
      writes++;
    } catch (_) {
      // A vault that cannot be written must never break the app; the manual
      // export in settings surfaces the error properly.
    }
  }

  /// Writes anything still queued straight away. Used when leaving a day so a
  /// half-typed note is not lost to the debounce.
  Future<void> flush() async {
    _dayTimer?.cancel();
    _sidecarTimer?.cancel();
    await _run(_pendingDay);
    await _run(_pendingSidecars);
    _pendingDay = null;
    _pendingSidecars = null;
  }
}
