import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:app_settings/app_settings.dart';



class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const String _prefKey = 'morning_suggestions_enabled';
  static const int _morningNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  // ─── Permission ───────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    // Android 13+
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
n
    final alreadyGranted = await android.areNotificationsEnabled();
    if (alreadyGranted) return true;

    final granted = await android.requestNotificationsPermission();
    if (granted ?? false) return true;

    await AppSettings.openAppSettings();
    return false;
    }

    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ─── Preference persistence ───────────────────────────────────────────────

  Future<bool> isMorningSuggestionsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> _savePreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  // ─── Schedule / cancel ────────────────────────────────────────────────────

  /// Enables morning notifications at 08:00 local time daily.
  /// Requests permission first — returns false if denied.
  Future<bool> enableMorningSuggestions() async {
    await initialize();

    final granted = await requestPermission();
    if (!granted) return false;

    await _scheduleDailyMorningNotification();
    await _savePreference(true);
    return true;
  }

  Future<void> disableMorningSuggestions() async {
    await initialize();
    await _plugin.cancel(_morningNotificationId);
    await _savePreference(false);
  }

  Future<void> _scheduleDailyMorningNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'morning_suggestions',
      'Morning Style Suggestions',
      channelDescription:
          'Daily morning notifications with your outfit idea for the day',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 08:00 today, or tomorrow if already past 08:00
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8, // 08:00
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _morningNotificationId,
      '✨ Your style idea for today',
      'Open Everywear to see your personalised outfit suggestion.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );

    if (kDebugMode) debugPrint('✅ Morning notification scheduled for 08:00 daily');
  }

  /// Call on app launch to reschedule if preference is on
  /// (needed after phone restart).
  Future<void> restoreIfEnabled() async {
    await initialize();
    final enabled = await isMorningSuggestionsEnabled();
    if (enabled) {
      await _scheduleDailyMorningNotification();
    }
  }
}
