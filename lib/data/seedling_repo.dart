import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/day_key.dart';
import '../logic/mirror_doc_id.dart';
import '../logic/recent_emoji.dart';
import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../models/someday_item.dart';
import '../models/review_template.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/week_review.dart';

/// Everything Seedling reads from and writes to Firestore, for one signed-in
/// user. Firestore types stop here — callers deal in [Task], [Tag] and
/// strings.
///
/// Business rules live in `lib/logic/`: this class stores and fetches, it does
/// not decide what belongs on a day page.
class SeedlingRepo {
  SeedlingRepo(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      _firestore.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _user.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _tags =>
      _user.collection('tags');

  CollectionReference<Map<String, dynamic>> get _days =>
      _user.collection('days');

  // ponytail: single all-tasks listener; add date-bounded queries if the
  // collection gets big.
  Stream<List<Task>> watchTasks() => _tasks.snapshots().map(
        (snap) =>
            snap.docs.map((d) => Task.fromMap(d.id, d.data())).toList(),
      );

  Stream<List<Tag>> watchTags() =>
      _tags.orderBy('sortOrder').snapshots().map(
            (snap) =>
                snap.docs.map((d) => Tag.fromMap(d.id, d.data())).toList(),
          );

  /// Empty string when the day has no note yet.
  Stream<String> watchNote(String dayKey) => _days
      .doc(dayKey)
      .snapshots()
      .map((snap) => snap.data()?['note'] as String? ?? '');

  Future<void> addTask(
    String title, {
    required String date,
    String? tagId,
    String? time,
  }) =>
      _tasks.add({
        'title': title,
        'date': date,
        'createdDate': todayKey(),
        'tagId': tagId,
        'time': time,
        'completedOnDate': null,
      });

  /// Pass null to uncheck.
  Future<void> setCompleted(Task t, String? onDayKey) =>
      _tasks.doc(t.id).update({'completedOnDate': onDayKey});

  Future<void> snooze(Task t, String toDayKey) =>
      _tasks.doc(t.id).update({'date': toDayKey});

  /// Null clears the time, moving the task out of the timed list.
  Future<void> setTime(Task t, String? time) =>
      _tasks.doc(t.id).update({'time': time});

  /// Null clears the tag.
  Future<void> setTag(Task t, String? tagId) =>
      _tasks.doc(t.id).update({'tagId': tagId});

  Future<void> deleteTask(Task t) => _tasks.doc(t.id).delete();

  /// Adds [deltaMinutes] to the time logged against [dayKey], never letting a
  /// day go negative. Zero removes the entry rather than storing a 0.
  Future<void> logTime(Task t, String dayKey, int deltaMinutes) {
    final updated = (t.minutesOn(dayKey) + deltaMinutes).clamp(0, 24 * 60);
    return _tasks.doc(t.id).update({
      'timeEntries.$dayKey':
          updated == 0 ? FieldValue.delete() : updated,
    });
  }

  Future<void> upsertTag(Tag t) => _tags.doc(t.id).set(t.toMap());

  /// Merges, so a day document keeps whatever else it holds.
  Future<void> saveNote(String dayKey, String text) =>
      _days.doc(dayKey).set({'note': text}, SetOptions(merge: true));

  // --- daily questions ---

  CollectionReference<Map<String, dynamic>> get _questions =>
      _user.collection('questions');

  /// Every question, including deactivated ones — the settings screen needs
  /// those, and a day page filters them out itself.
  Stream<List<DailyQuestion>> watchQuestions() =>
      _questions.orderBy('sortOrder').snapshots().map((snap) => snap.docs
          .map((d) => DailyQuestion.fromMap(d.id, d.data()))
          .toList());

  Future<void> upsertQuestion(DailyQuestion question) =>
      _questions.doc(question.id).set(question.toMap());

  Future<void> deleteQuestion(DailyQuestion question) =>
      _questions.doc(question.id).delete();

  // --- someday ---

  CollectionReference<Map<String, dynamic>> get _someday =>
      _user.collection('someday');

  /// Highest priority first — the pull-into-today flow offers the top few.
  Stream<List<SomedayItem>> watchSomeday() =>
      _someday.orderBy('priority').snapshots().map((snap) =>
          snap.docs.map((d) => SomedayItem.fromMap(d.id, d.data())).toList());

  Future<void> addSomeday(String title, {String? tagId, int priority = 0}) =>
      _someday.add({'title': title, 'tagId': tagId, 'priority': priority});

  Future<void> upsertSomeday(SomedayItem item) =>
      _someday.doc(item.id).set(item.toMap());

  Future<void> deleteSomeday(SomedayItem item) =>
      _someday.doc(item.id).delete();

  /// Moves a someday item onto a day, and takes it off the someday list — the
  /// whole point is that it stops being "someday".
  Future<void> promoteSomeday(SomedayItem item, String dayKey) async {
    await addTask(item.title, date: dayKey, tagId: item.tagId);
    await deleteSomeday(item);
  }

  // --- week reviews ---

  DocumentReference<Map<String, dynamic>> get _template =>
      _user.collection('config').doc('reviewTemplate');

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _user.collection('reviews');

  /// Falls back to the starter template so the first review is not a blank
  /// page waiting to be configured.
  Stream<ReviewTemplate> watchReviewTemplate() =>
      _template.snapshots().map((snap) => snap.exists
          ? ReviewTemplate.fromMap(snap.data() ?? const {})
          : ReviewTemplate.starter);

  Future<void> saveReviewTemplate(ReviewTemplate template) =>
      _template.set(template.toMap());

  Stream<WeekReview?> watchReview(String weekKey) => _reviews
      .doc(weekKey)
      .snapshots()
      .map((snap) =>
          snap.exists ? WeekReview.fromMap(weekKey, snap.data() ?? const {}) : null);

  Future<void> saveReview(WeekReview review) =>
      _reviews.doc(review.weekKey).set(review.toMap());

  DocumentReference<Map<String, dynamic>> get _emoji =>
      _user.collection('config').doc('recentEmoji');

  /// The emoji you have reached for lately, most recent first. Stored on the
  /// account rather than the device so the strip is the same everywhere.
  Stream<List<String>> watchRecentEmoji() => _emoji.snapshots().map((snap) =>
      ((snap.data()?['emoji'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toList());

  /// Records that [emoji] was just used, keeping the list to ten.
  Future<void> noteEmojiUsed(String emoji) async {
    final current = await watchRecentEmoji().first;
    final next = promoteEmoji(current, emoji);
    if (next.isEmpty) return;
    await _emoji.set({'emoji': next});
  }

  Stream<List<String>> watchReviewedWeeks() => _reviews
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toList()..sort());

  /// Calendar events you have ticked off, per day.
  ///
  /// Seedling never writes to your calendar, so "done" lives here. Keyed by
  /// day as well as event so a repeating event can be done today and still
  /// waiting tomorrow.
  Stream<Set<String>> watchDoneEvents(String dayKey) =>
      _days.doc(dayKey).snapshots().map((snap) =>
          ((snap.data()?['doneEvents'] as List<dynamic>?) ?? const [])
              .map((id) => id as String)
              .toSet());

  Future<void> setEventDone(String dayKey, String eventId, bool done) =>
      _days.doc(dayKey).set({
        'doneEvents':
            done ? FieldValue.arrayUnion([eventId]) : FieldValue.arrayRemove([eventId]),
      }, SetOptions(merge: true));

  // --- calendar mirror ---

  CollectionReference<Map<String, dynamic>> get _calendarMirror =>
      _user.collection('calendarMirror');

  /// What the phone published, for machines that cannot read a calendar.
  Future<List<CalendarEvent>> readCalendarMirror(String from, String to) async {
    final snap = await _calendarMirror
        .where('dayKey', isGreaterThanOrEqualTo: from)
        .where('dayKey', isLessThanOrEqualTo: to)
        .get();
    return snap.docs
        .map((d) => CalendarEvent.fromMap(d.id, d.data()))
        .toList();
  }

  /// Replaces the window [from]..[to] with [events].
  ///
  /// A replace rather than a merge, so an appointment deleted or moved in the
  /// real calendar disappears here too instead of lingering forever.
  Future<void> publishCalendarMirror(
    List<CalendarEvent> events, {
    required String from,
    required String to,
  }) async {
    final existing = await _calendarMirror
        .where('dayKey', isGreaterThanOrEqualTo: from)
        .where('dayKey', isLessThanOrEqualTo: to)
        .get();

    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final event in events) {
      batch.set(_calendarMirror.doc(mirrorDocId(event.id)), event.toMap());
    }
    await batch.commit();
  }

  // --- hidden calendar events ---

  DocumentReference<Map<String, dynamic>> get _blacklist =>
      _user.collection('config').doc('blacklist');

  /// The hide keys: a repeating event's series id, or an exact title.
  Stream<Set<String>> watchHiddenEvents() =>
      _blacklist.snapshots().map((snap) =>
          ((snap.data()?['keys'] as List<dynamic>?) ?? const [])
              .map((k) => k as String)
              .toSet());

  Future<void> hideEvent(String key) => _blacklist.set(
      {'keys': FieldValue.arrayUnion([key])}, SetOptions(merge: true));

  Future<void> unhideEvent(String key) => _blacklist.set(
      {'keys': FieldValue.arrayRemove([key])}, SetOptions(merge: true));

  /// Answers for one day, keyed by question id.
  Stream<Map<String, String>> watchAnswers(String dayKey) =>
      _days.doc(dayKey).snapshots().map((snap) {
        final raw = snap.data()?['questionAnswers'] as Map<String, dynamic>?;
        return {
          for (final entry in (raw ?? const {}).entries)
            entry.key: entry.value as String,
        };
      });

  /// Passing a null [value] clears the answer rather than storing an empty one.
  Future<void> setAnswer(String dayKey, String questionId, String? value) =>
      _days.doc(dayKey).set({
        'questionAnswers': {questionId: value ?? FieldValue.delete()},
      }, SetOptions(merge: true));
}
