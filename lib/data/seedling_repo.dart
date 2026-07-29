import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/day_key.dart';
import '../logic/jira_ref.dart';
import '../logic/mirror_doc_id.dart';
import '../logic/recent_emoji.dart';
import '../models/calendar_event.dart';
import '../models/daily_question.dart';
import '../logic/worklog.dart';
import '../models/event_extras.dart';
import '../models/jira_ticket.dart';
import '../models/topic.dart';
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

  /// Merges rather than updates, so a rename cannot drop the time entries or
  /// the completion the task was carrying.
  Future<void> renameTask(Task t, String title) =>
      _tasks.doc(t.id).set({'title': title}, SetOptions(merge: true));

  /// Null clears the tag.
  Future<void> setTag(Task t, String? tagId) =>
      _tasks.doc(t.id).update({'tagId': tagId});

  /// Null unlinks the ticket.
  Future<void> setJira(Task t, JiraRef? ref) async {
    await _tasks.doc(t.id).update({'jira': ref?.toMap()});
    // Tagging something is what makes a ticket recent, wherever you did it.
    if (ref != null) await touchJiraTicket(ref, DateTime.now());
  }

  /// The Jira site last used, so a bare key like MAF-1234 is enough next time.
  Stream<String?> watchJiraSite() => _user
      .collection('config')
      .doc('jira')
      .snapshots()
      .map((snap) => snap.data()?['site'] as String?);

  Future<void> rememberJiraSite(String site) =>
      _user.collection('config').doc('jira').set({'site': site});

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

  /// Sets the day's logged time outright, for when it is typed rather than
  /// stepped.
  Future<void> setTimeLogged(Task t, String dayKey, int minutes) =>
      _tasks.doc(t.id).update({
        'timeEntries.$dayKey':
            minutes <= 0 ? FieldValue.delete() : minutes.clamp(0, 24 * 60),
      });

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

  /// Refiles an idea under another project, or under none. Written on its own
  /// rather than through [upsertSomeday] so a drag cannot clobber a title
  /// edited somewhere else at the same moment.
  Future<void> setSomedayTag(SomedayItem item, String? tagId) =>
      _someday.doc(item.id).set({'tagId': tagId}, SetOptions(merge: true));

  Future<void> deleteSomeday(SomedayItem item) =>
      _someday.doc(item.id).delete();

  /// Sends a task back to the someday list. The mirror of promoting one: it
  /// stops being a thing for a particular day.
  Future<void> demoteToSomeday(Task task) async {
    final existing = await watchSomeday().first;
    await addSomeday(task.title,
        tagId: task.tagId, priority: existing.length);
    await deleteTask(task);
  }

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

  // --- what Seedling adds to a calendar event ---

  CollectionReference<Map<String, dynamic>> get _eventExtras =>
      _user.collection('eventExtras');

  /// Keyed by the event's hide key, so a repeating event carries one tag
  /// rather than one per occurrence.
  Stream<Map<String, EventExtras>> watchEventExtras() =>
      _eventExtras.snapshots().map((snap) => {
            for (final doc in snap.docs)
              (doc.data()['key'] as String? ?? doc.id):
                  EventExtras.fromMap(doc.data()),
          });

  Future<void> setEventExtras(String hideKey, EventExtras extras) {
    final doc = _eventExtras.doc(mirrorDocId(hideKey));
    // Nothing left to say about it, so stop keeping a record.
    if (extras.isEmpty) return doc.delete();
    return doc.set({...extras.toMap(), 'key': hideKey});
  }

  // --- the tickets you tag things with ---

  CollectionReference<Map<String, dynamic>> get _jiraTickets =>
      _user.collection('jiraTickets');

  /// Most recently used first, so tagging is a tap rather than a search.
  Stream<List<JiraTicket>> watchJiraTickets() =>
      _jiraTickets.snapshots().map((snap) =>
          snap.docs.map((d) => JiraTicket.fromMap(d.id, d.data())).toList()
            ..sort(JiraTicket.byRecency));

  /// Merges, so importing a batch cannot wipe the last-used times that make
  /// the list worth reading.
  Future<void> rememberJiraTickets(List<JiraTicket> tickets) async {
    for (final ticket in tickets) {
      await _jiraTickets.doc(ticket.key).set({
        'key': ticket.key,
        'site': ticket.site,
        if (ticket.summary != null) 'summary': ticket.summary,
        if (ticket.lastUsed != null)
          'lastUsed': ticket.lastUsed!.toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> touchJiraTicket(JiraRef ref, DateTime when) =>
      _jiraTickets.doc(ref.key).set({
        'key': ref.key,
        'site': ref.site,
        'lastUsed': when.toIso8601String(),
      }, SetOptions(merge: true));

  // --- standing topics ---

  CollectionReference<Map<String, dynamic>> get _topics =>
      _user.collection('topics');

  /// The rows on the timesheet that are not tasks: meetings, maintenance,
  /// the work that recurs forever.
  Stream<List<Topic>> watchTopics() => _topics.snapshots().map((snap) =>
      snap.docs.map((d) => Topic.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  Future<void> upsertTopic(Topic topic) =>
      _topics.doc(topic.id).set(topic.toMap());

  Future<void> deleteTopic(Topic topic) => _topics.doc(topic.id).delete();

  Future<void> setTopicMinutes(Topic topic, String dayKey, int minutes) =>
      _topics.doc(topic.id).set({
        'minutes': {
          dayKey: minutes <= 0 ? FieldValue.delete() : minutes.clamp(0, 24 * 60),
        },
      }, SetOptions(merge: true));

  // --- time already sent to Jira ---

  CollectionReference<Map<String, dynamic>> get _sentWorklogs =>
      _user.collection('sentWorklogs');

  /// Keyed by source and day, so pressing send twice cannot log the same hour
  /// twice. Kept on the account rather than the device: the time might be
  /// logged on the phone and sent from the Mac.
  Stream<Map<String, SentWorklog>> watchSentWorklogs() =>
      _sentWorklogs.snapshots().map((snap) => {
            for (final doc in snap.docs)
              (doc.data()['key'] as String? ?? doc.id):
                  SentWorklog.fromMap(doc.data()),
          });

  Future<void> recordSentWorklog(String key, SentWorklog worklog) =>
      _sentWorklogs.doc(mirrorDocId(key)).set({...worklog.toMap(), 'key': key});

  Future<void> forgetSentWorklog(String key) =>
      _sentWorklogs.doc(mirrorDocId(key)).delete();

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

    // One document per occurrence, not per event: every Tuesday of a weekly
    // standup carries the same EventKit id, and keying on that alone kept one
    // of them and silently dropped the rest.
    final writes = <void Function(WriteBatch)>[
      for (final doc in existing.docs) (b) => b.delete(doc.reference),
      for (final event in events)
        (b) => b.set(
              _calendarMirror
                  .doc(mirrorOccurrenceId(event.id, event.dayKey, event.time)),
              event.toMap(),
            ),
    ];

    // Firestore refuses a batch over 500 operations, and two months of a busy
    // calendar is well past that — it used to fail the lot rather than write
    // some of it.
    for (var i = 0; i < writes.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final write in writes.skip(i).take(_batchLimit)) {
        write(batch);
      }
      await batch.commit();
    }

    // Only after every batch landed, so a half-written mirror never reports
    // itself as whole.
    await _calendarStatus.set({
      'count': events.length,
      'at': DateTime.now().toIso8601String(),
      'from': from,
      'to': to,
    });
  }

  DocumentReference<Map<String, dynamic>> get _calendarStatus =>
      _user.collection('config').doc('calendarMirror');

  /// What the sharing device last managed to publish. Null until one has.
  /// Sharing used to fail silently, which is a hard thing to notice on the
  /// device that is only reading.
  Stream<CalendarShare?> watchCalendarShare() =>
      _calendarStatus.snapshots().map((snap) {
        final data = snap.data();
        if (data == null) return null;
        return CalendarShare(
          count: (data['count'] as num?)?.toInt() ?? 0,
          at: DateTime.tryParse(data['at'] as String? ?? ''),
        );
      });

  /// Firestore's own ceiling is 500; the margin costs nothing.
  static const int _batchLimit = 400;

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

  /// The days you actually did something on: wrote a note, answered a daily
  /// question or ticked an appointment off. Tasks are not read here — the day
  /// page already has them, and it folds in the days it was checked off on.
  Stream<Set<String>> watchActiveDays() => _days.snapshots().map((snap) => {
        for (final doc in snap.docs)
          if (_hasActivity(doc.data())) doc.id,
      });

  static bool _hasActivity(Map<String, dynamic> day) =>
      (day['note'] as String? ?? '').trim().isNotEmpty ||
      (day['questionAnswers'] as Map<String, dynamic>? ?? const {}).isNotEmpty ||
      (day['doneEvents'] as List<dynamic>? ?? const []).isNotEmpty;

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

/// The last calendar publish, as the reading devices see it.
class CalendarShare {
  const CalendarShare({required this.count, this.at});

  final int count;
  final DateTime? at;
}
