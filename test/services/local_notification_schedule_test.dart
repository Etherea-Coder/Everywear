import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:everywear/services/local_notification_schedule.dart';

void main() {
  late tz.Location newYork;
  setUpAll(() {
    timezone_data.initializeTimeZones();
    newYork = tz.getLocation('America/New_York');
  });

  group('nextDailyLocalTime', () {
    test('keeps 08:00 local across spring daylight-saving transition', () {
      final now = tz.TZDateTime(newYork, 2026, 3, 7, 9);

      final next = nextDailyLocalTime(location: newYork, now: now);

      expect(next.year, 2026);
      expect(next.month, 3);
      expect(next.day, 8);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });

    test('uses today when 08:00 is still ahead', () {
      final now = tz.TZDateTime(newYork, 2026, 6, 1, 7, 59);

      final next = nextDailyLocalTime(location: newYork, now: now);

      expect(next.day, 1);
      expect(next.hour, 8);
    });

    test('moves an exact 08:00 boundary to the next day', () {
      final now = tz.TZDateTime(newYork, 2026, 6, 1, 8);

      final next = nextDailyLocalTime(location: newYork, now: now);

      expect(next.day, 2);
      expect(next.hour, 8);
    });

    test('rejects an invalid local hour', () {
      final now = tz.TZDateTime(newYork, 2026, 6, 1, 7);

      expect(
        () => nextDailyLocalTime(location: newYork, now: now, hour: 24),
        throwsArgumentError,
      );
    });
  });
}
