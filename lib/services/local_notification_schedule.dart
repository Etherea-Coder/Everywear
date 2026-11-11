import 'package:timezone/timezone.dart' as tz;

/// Returns the next occurrence of [hour] in [location]'s local calendar.
/// Constructing the next calendar date avoids a 24-hour duration shifting the
/// reminder across daylight-saving transitions.
tz.TZDateTime nextDailyLocalTime({
  required tz.Location location,
  required tz.TZDateTime now,
  int hour = 8,
}) {
  if (hour < 0 || hour > 23) {
    throw ArgumentError.value(hour, 'hour', 'must be between 0 and 23');
  }

  final today = tz.TZDateTime(location, now.year, now.month, now.day, hour);
  if (today.isAfter(now)) return today;

  return tz.TZDateTime(location, now.year, now.month, now.day + 1, hour);
}
