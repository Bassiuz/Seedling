import '../models/event_extras.dart';
import '../models/task.dart';
import '../models/topic.dart';
import 'jira_ref.dart';

/// A worklog Seedling has already put in Jira.
///
/// The minutes are kept alongside the id so a later correction can be told
/// from a re-send: the same hour sent twice is worse for a timesheet than
/// never sending it at all.
class SentWorklog {
  const SentWorklog({required this.id, required this.minutes});

  final String id;
  final int minutes;

  factory SentWorklog.fromMap(Map<String, dynamic> map) => SentWorklog(
        id: map['id'] as String? ?? '',
        minutes: (map['minutes'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {'id': id, 'minutes': minutes};
}

/// What has to happen in Jira for one piece of logged time.
enum WorklogVerb {
  /// Never sent. Post it.
  create,

  /// Sent, then the number changed here. Correct the one that is there.
  update,

  /// Sent, then taken back to nothing. Remove it, rather than leaving an
  /// hour in the timesheet that you decided you had not worked.
  delete,
}

class WorklogAction {
  const WorklogAction({
    required this.verb,
    required this.jira,
    required this.dayKey,
    required this.minutes,
    required this.title,
    required this.key,
    this.sentId,
  });

  final WorklogVerb verb;
  final JiraRef jira;
  final String dayKey;

  /// What it should be after this action. Zero for a delete.
  final int minutes;
  final String title;

  /// Identifies the source and day, and is how the sent record is filed.
  final String key;

  /// The Jira worklog id, for an update or a delete.
  final String? sentId;
}

/// The key a sent worklog is filed under: what it came from, and which day.
String worklogKey(String sourceId, String dayKey) => '$sourceId@$dayKey';

/// Everything that is out of step between the time logged here and the
/// worklogs already in Jira.
///
/// Only time on something with a ticket counts — an hour on an untagged task
/// has nowhere to go. Days are walked from both sides: the time logged now,
/// and the days already sent, so time taken back to zero is noticed too.
List<WorklogAction> worklogActions({
  required List<Task> tasks,
  required Map<String, EventExtras> events,
  required Map<String, SentWorklog> sent,
  List<Topic> topics = const [],
}) {
  final actions = <WorklogAction>[];

  void consider({
    required String sourceId,
    required JiraRef? jira,
    required String title,
    required Map<String, int> minutes,
  }) {
    if (jira == null) return;
    final days = <String>{
      ...minutes.keys,
      for (final entry in sent.entries)
        if (entry.key.startsWith('$sourceId@'))
          entry.key.substring(sourceId.length + 1),
    };

    for (final day in days) {
      final key = worklogKey(sourceId, day);
      final already = sent[key];
      final now = minutes[day] ?? 0;

      if (already == null) {
        if (now > 0) {
          actions.add(WorklogAction(
            verb: WorklogVerb.create,
            jira: jira,
            dayKey: day,
            minutes: now,
            title: title,
            key: key,
          ));
        }
        continue;
      }
      if (now <= 0) {
        actions.add(WorklogAction(
          verb: WorklogVerb.delete,
          jira: jira,
          dayKey: day,
          minutes: 0,
          title: title,
          key: key,
          sentId: already.id,
        ));
      } else if (now != already.minutes) {
        actions.add(WorklogAction(
          verb: WorklogVerb.update,
          jira: jira,
          dayKey: day,
          minutes: now,
          title: title,
          key: key,
          sentId: already.id,
        ));
      }
    }
  }

  for (final task in tasks) {
    consider(
      sourceId: task.id,
      jira: task.jira,
      title: task.title,
      minutes: task.timeEntries,
    );
  }
  for (final entry in events.entries) {
    consider(
      sourceId: entry.key,
      jira: entry.value.jira,
      title: entry.value.title ?? entry.key,
      minutes: entry.value.minutes,
    );
  }

  for (final topic in topics) {
    consider(
      sourceId: topic.id,
      jira: topic.jira,
      title: topic.title,
      minutes: topic.minutes,
    );
  }

  // Oldest first, then by ticket, so a week reads down the page the way it
  // was lived.
  actions.sort((a, b) {
    final byDay = a.dayKey.compareTo(b.dayKey);
    return byDay != 0 ? byDay : a.jira.key.compareTo(b.jira.key);
  });
  return actions;
}
