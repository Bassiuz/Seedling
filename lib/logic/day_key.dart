String dayKeyOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOfKey(String key) => DateTime.parse(key);

String addDays(String key, int days) =>
    dayKeyOf(dateOfKey(key).add(Duration(days: days)));

String todayKey() => dayKeyOf(DateTime.now());
