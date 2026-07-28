import 'day_key.dart';

/// The calendar page for the month containing [anyDay], Monday first.
///
/// Always six rows, so swiping between months does not make the sheet jump a
/// row taller and shorter. Days outside the month come back as null rather
/// than as greyed neighbours — this is a jump list, not a wall planner.
List<String?> monthGrid(String anyDay) {
  final d = dateOfKey(anyDay);
  final first = DateTime(d.year, d.month, 1);
  final lead = first.weekday - DateTime.monday;
  final days = DateTime(d.year, d.month + 1, 0).day;

  return [
    for (var i = 0; i < 42; i++)
      if (i < lead || i - lead >= days)
        null
      else
        dayKeyOf(DateTime(d.year, d.month, i - lead + 1)),
  ];
}

/// The same day number in another month, clamped to that month's length so
/// stepping from the 31st never skips February.
String addMonths(String key, int months) {
  final d = dateOfKey(key);
  final target = DateTime(d.year, d.month + months, 1);
  final length = DateTime(target.year, target.month + 1, 0).day;
  return dayKeyOf(DateTime(target.year, target.month, d.day.clamp(1, length)));
}

/// How many months [b] is after [a], ignoring the day of the month.
int monthsBetween(String a, String b) {
  final from = dateOfKey(a);
  final to = dateOfKey(b);
  return (to.year - from.year) * 12 + to.month - from.month;
}
