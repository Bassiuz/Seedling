import 'day_key.dart';
import 'week_key.dart';

/// What a page in the day pager shows.
///
/// Weeks run Monday to Sunday and the review of a week sits straight after its
/// Sunday, so scrolling forward reaches it exactly where you would write it —
/// at the turn of the week — rather than behind a button.
class DayPageSlot {
  const DayPageSlot.day(String this.dayKey) : weekKey = null;
  const DayPageSlot.review(String this.weekKey) : dayKey = null;

  final String? dayKey;
  final String? weekKey;

  bool get isReview => weekKey != null;
}

/// Seven days, then the review of the week they made up.
const int slotsPerWeek = 8;

/// Floor division, so the week before the anchor is -1 rather than 0.
int _floorDiv(int a, int b) => (a - (a % b + b) % b) ~/ b;

/// How many days [day] is after [anchorMonday].
int _daysFrom(String anchorMonday, String day) =>
    DateTime.utc(
          dateOfKey(day).year,
          dateOfKey(day).month,
          dateOfKey(day).day,
        )
        .difference(DateTime.utc(
          dateOfKey(anchorMonday).year,
          dateOfKey(anchorMonday).month,
          dateOfKey(anchorMonday).day,
        ))
        .inDays;

/// The page index showing [day], counting from the Monday at page zero.
int pageForDay(String anchorMonday, String day) {
  final days = _daysFrom(anchorMonday, day);
  final week = _floorDiv(days, 7);
  final slot = days - week * 7;
  return week * slotsPerWeek + slot;
}

/// The page index of the review written at the end of [day]'s week.
int pageForReviewOfWeekContaining(String anchorMonday, String day) {
  final week = _floorDiv(_daysFrom(anchorMonday, day), 7);
  return week * slotsPerWeek + 7;
}

/// What page [index] shows.
DayPageSlot pageContent(String anchorMonday, int index) {
  final week = _floorDiv(index, slotsPerWeek);
  final slot = index - week * slotsPerWeek;
  final monday = addDays(anchorMonday, week * 7);

  if (slot < 7) return DayPageSlot.day(addDays(monday, slot));
  // The review belongs to the week that just ended, which is this Monday's.
  return DayPageSlot.review(weekKeyOf(monday));
}
