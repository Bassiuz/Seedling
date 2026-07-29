import '../models/event_extras.dart';
import '../models/jira_ticket.dart';
import '../models/task.dart';
import '../models/topic.dart';
import 'day_key.dart';

/// Every ticket you have ever put on anything, with the last day you did.
///
/// The tagger's list would otherwise start empty and stay empty until you
/// pasted something in — while the app already knows every ticket you have
/// used, and which ones you used most recently. Recency comes from the work
/// itself: the latest day a ticket carries time, was finished, or was planned
/// for.
List<JiraTicket> ticketsInUse({
  required List<Task> tasks,
  List<Topic> topics = const [],
  Map<String, EventExtras> events = const {},
}) {
  final latest = <String, ({String site, String day})>{};

  void seen(String? key, String? site, Iterable<String?> days) {
    if (key == null || site == null) return;
    final day = days.nonNulls.where((d) => d.isNotEmpty).fold<String?>(
        null, (best, d) => best == null || d.compareTo(best) > 0 ? d : best);
    if (day == null) return;
    final held = latest[key];
    if (held == null || day.compareTo(held.day) > 0) {
      latest[key] = (site: site, day: day);
    }
  }

  for (final task in tasks) {
    seen(task.jira?.key, task.jira?.site, [
      task.date,
      task.completedOnDate,
      ...task.timeEntries.keys,
    ]);
  }
  for (final topic in topics) {
    seen(topic.jira?.key, topic.jira?.site, topic.minutes.keys);
  }
  for (final extras in events.values) {
    seen(extras.jira?.key, extras.jira?.site, extras.minutes.keys);
  }

  return [
    for (final entry in latest.entries)
      JiraTicket(
        key: entry.key,
        site: entry.value.site,
        lastUsed: dateOfKey(entry.value.day),
      ),
  ]..sort(JiraTicket.byRecency);
}

/// Jira's `key in (…)` has a length limit and a paste can be long, so the
/// lookup goes out in handfuls.
List<List<String>> inBatches(List<String> keys, {int size = 50}) => [
      for (var i = 0; i < keys.length; i += size)
        keys.sublist(i, i + size > keys.length ? keys.length : i + size),
    ];
