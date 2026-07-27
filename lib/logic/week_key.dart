import 'day_key.dart';

/// Weeks are ISO-8601: they run Monday to Sunday, and a week belongs to the
/// year containing its Thursday. Keys look like `2026-W31`, which sorts
/// chronologically within a year and matches the vault's review filenames.
String weekKeyOf(String dayKey) {
  final date = dateOfKey(dayKey);
  // The Thursday of this week settles both the year and the number.
  final thursday =
      DateTime(date.year, date.month, date.day + (4 - date.weekday));
  // In UTC: a local difference loses an hour across the clock change, and
  // `inDays` truncates that into an off-by-one for half the year.
  final dayOfYear = DateTime.utc(thursday.year, thursday.month, thursday.day)
          .difference(DateTime.utc(thursday.year, 1, 1))
          .inDays +
      1;
  final week = (dayOfYear - 1) ~/ 7 + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

/// The Monday that starts the week a day falls in.
String weekStartOf(String dayKey) {
  final date = dateOfKey(dayKey);
  return dayKeyOf(DateTime(date.year, date.month, date.day - (date.weekday - 1)));
}

/// The Sunday that ends it.
String weekEndOf(String dayKey) => addDays(weekStartOf(dayKey), 6);

/// The review for a week is offered from its Sunday, so it can be written
/// before Monday rather than in a rush on the day.
bool isReviewDay(String dayKey) => dateOfKey(dayKey).weekday == DateTime.sunday;

/// Reviewing on Sunday writes the week just ending; from Monday on you are
/// looking back at the week before.
String reviewWeekFor(String dayKey) => dateOfKey(dayKey).weekday ==
        DateTime.sunday
    ? weekKeyOf(dayKey)
    : weekKeyOf(addDays(weekStartOf(dayKey), -1));
