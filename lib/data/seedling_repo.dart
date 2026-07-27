import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/day_key.dart';
import '../models/daily_question.dart';
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
