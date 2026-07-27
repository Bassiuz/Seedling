import '../models/task.dart';

/// Which day pages a task shows up on, and how it looks there.
///
/// The rule: a task is visible on day D when D is its planned date, or when D
/// falls after the planned date and on or before the day it was checked off —
/// or, while it is still open, on or before today. So an unfinished task
/// carries forward until today, and checking it off on any page stops it
/// carrying past that page without erasing it from the days it was already on.
///
/// Day keys are `yyyy-MM-dd`, so string comparison is chronological.
bool taskVisibleOn(Task t, String day, String today) {
  if (day == t.date) return true;
  if (day.compareTo(t.date) < 0) return false;
  final lastDay = t.completedOnDate ?? today;
  return day.compareTo(lastDay) <= 0;
}

/// How a task's checkbox reads on a given day page.
enum TaskCheckState {
  /// Not done — tapping checks it off on this day.
  open,

  /// Checked off on this very day — tapping unchecks it.
  checkedHere,

  /// Checked off on a later day; shown here as history, not interactive.
  doneLater,
}

TaskCheckState checkStateOn(Task t, String day) {
  if (t.completedOnDate == null) return TaskCheckState.open;
  return t.completedOnDate == day
      ? TaskCheckState.checkedHere
      : TaskCheckState.doneLater;
}

/// The tasks belonging on [day]'s page: timed ones first in clock order, then
/// untimed ones oldest first.
List<Task> tasksForDay(List<Task> all, String day, String today) {
  final visible = all.where((t) => taskVisibleOn(t, day, today)).toList()
    ..sort((a, b) {
      if (a.isTimed != b.isTimed) return a.isTimed ? -1 : 1;
      return a.isTimed
          ? a.time!.compareTo(b.time!)
          : a.createdDate.compareTo(b.createdDate);
    });
  return visible;
}
