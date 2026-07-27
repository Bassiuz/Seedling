import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/day_key.dart';
import '../models/daily_question.dart';
import '../models/someday_item.dart';
import '../models/tag.dart';
import '../models/task.dart';

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
