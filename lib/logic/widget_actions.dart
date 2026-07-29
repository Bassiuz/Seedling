import 'dart:convert';

/// Ticking something off on the widget, on its way to the app.
///
/// The widget cannot write to Firestore itself. It runs in a background
/// isolate, and a second isolate opening the same offline database is exactly
/// what produced "LOCK: Resource temporarily unavailable" earlier in this
/// project — so the tap is queued here, the widget redraws immediately as
/// though it were done, and the app writes it for real the next time it runs.
class PendingToggles {
  const PendingToggles(this.taskIds);

  final List<String> taskIds;

  bool get isEmpty => taskIds.isEmpty;

  static const empty = PendingToggles([]);

  /// Tolerant of anything: a widget store that has been corrupted or is from
  /// an older version must not stop the app starting.
  factory PendingToggles.parse(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return empty;
      return PendingToggles([
        for (final entry in decoded)
          if (entry is String && entry.isNotEmpty) entry,
      ]);
    } catch (_) {
      return empty;
    }
  }

  /// Queued once, however many times it was tapped.
  PendingToggles plus(String taskId) =>
      taskIds.contains(taskId) ? this : PendingToggles([...taskIds, taskId]);

  String toJson() => jsonEncode(taskIds);
}

/// The task id in `seedling://toggle?id=…`, or null for anything else.
String? toggledTaskId(Uri? uri) {
  if (uri == null || uri.host != 'toggle') return null;
  final id = uri.queryParameters['id'];
  return id == null || id.isEmpty ? null : id;
}
