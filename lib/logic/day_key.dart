String dayKeyOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOfKey(String key) => DateTime.parse(key);

/// Calendar math, not `Duration(days:)`: a DST day is 23 or 25 hours long, so
/// adding 24 hours to 2026-10-25 lands back on 2026-10-25. DateTime normalises
/// out-of-range day numbers, so month and year boundaries still work.
String addDays(String key, int days) {
  final d = dateOfKey(key);
  return dayKeyOf(DateTime(d.year, d.month, d.day + days));
}

String todayKey() => dayKeyOf(DateTime.now());
