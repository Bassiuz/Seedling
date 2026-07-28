import '../models/task.dart';
import 'day_key.dart';
import 'rollover.dart';

/// What you would read out at a standup: what you finished the day before,
/// and what you have taken on for this one.
class Standup {
  const Standup({
    required this.day,
    required this.previousDay,
    required this.done,
    required this.planned,
  });

  final String day;
  final String previousDay;

  /// Checked off on [previousDay], whichever day it was planned for.
  final List<Task> done;

  /// On [day]'s list, finished or not — a standup is what you are on, not
  /// only what is left.
  final List<Task> planned;
}

/// Builds it from every task there is.
///
/// [previousDay] is the calendar day before, not the last working day: a
/// Monday standup covering only Sunday is a choice for the person reading it,
/// not for Seedling.
Standup standupFor(List<Task> all, String day) {
  final previous = addDays(day, -1);
  return Standup(
    day: day,
    previousDay: previous,
    done: [
      for (final task in all)
        if (task.completedOnDate == previous) task,
    ]..sort((a, b) => a.title.compareTo(b.title)),
    planned: tasksForDay(all, day, day),
  );
}
