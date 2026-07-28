/// Reads a typed duration into minutes.
///
/// The rules follow how you would say it out loud rather than a strict format:
///
/// | Typed  | Means        | Why                                    |
/// |--------|--------------|----------------------------------------|
/// | `3`    | 3 hours      | a bare number under 15 is a count of hours |
/// | `40`   | 40 minutes   | 40 hours is not a thing you log on a day   |
/// | `3.5`  | 3h 30m       | half an hour, written the decimal way      |
/// | `3:15` | 3h 15m       | written the clock way                      |
/// | `90m`  | 90 minutes   | a unit always wins over the guess           |
/// | `2h`   | 2 hours      |                                             |
///
/// Returns null for anything it cannot read, so a typo logs nothing rather
/// than something wrong.
int? parseDuration(String raw) {
  final input = raw.trim().toLowerCase().replaceAll(',', '.');
  if (input.isEmpty) return null;

  // Clock form: 3:15.
  final clock = RegExp(r'^(\d+):([0-5]?\d)$').firstMatch(input);
  if (clock != null) {
    return int.parse(clock.group(1)!) * 60 + int.parse(clock.group(2)!);
  }

  // With a unit, there is nothing to guess.
  final withUnit = RegExp(r'^(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes)$')
      .firstMatch(input);
  if (withUnit != null) {
    final value = double.parse(withUnit.group(1)!);
    final isHours = withUnit.group(2)!.startsWith('h');
    return (isHours ? value * 60 : value).round();
  }

  final number = double.tryParse(input);
  if (number == null || number < 0) return null;

  // A fraction only makes sense as hours: nobody logs 3.5 minutes.
  if (number != number.roundToDouble()) return (number * 60).round();

  /// Below this a bare number reads as hours; at or above it, as minutes.
  const hoursBelow = 15;
  final whole = number.round();
  return whole < hoursBelow ? whole * 60 : whole;
}
