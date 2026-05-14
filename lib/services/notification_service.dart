import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:app_settings/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './today_suggestion_service.dart';
import './style_service.dart';
import './weather_service.dart';


class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const String _prefKey = 'morning_suggestions_enabled';
  static const String _teaserKey = 'notification_teaser';
  static const String _defaultBody = 'Open Everywear to see your personalised outfit suggestion.';
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
    // ─── Android ───────────────────────────────────────────
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // 1. Check if already enabled
      final alreadyGranted = await android.areNotificationsEnabled();
      if (alreadyGranted == true) return true;

      // 2. Request permission (Android 13+)
      final granted = await android.requestNotificationsPermission();

      // 3. If the request returned true or null (Android < 13), treat as granted.
      if (granted ?? true) return true;

      // 4. The request returned false — but on some devices/versions this
      //    happens even when the user tapped "Allow" (race condition).
      //    Re-check the actual system state to be sure.
      final actuallyEnabled = await android.areNotificationsEnabled();
      if (actuallyEnabled == true) return true;

      // 5. Truly denied — open device settings so the user can enable manually
      await AppSettings.openAppSettings();
      return false;
    }

    // ─── iOS ────────────────────────────────────────────────
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // ─── Web / Desktop / Other ──────────────────────────────
    // If not Android or iOS, assume permissions are not required.
    return true;
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

    // Save preference first so the toggle updates even if scheduling
    // hits an edge-case failure (e.g. exact-alarm restriction).
    await _savePreference(true);

    try {
      final teaser = await _preGenerateTeaser();
      await _scheduleDailyMorningNotification(teaser: teaser);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Morning notification scheduling failed: $e');
      // Permission was granted and preference is saved — the notification
      // will be rescheduled on next app launch via restoreIfEnabled().
    }
    return true;
  }

  Future<void> disableMorningSuggestions() async {
    await initialize();
    await _plugin.cancel(_morningNotificationId);
    await _savePreference(false);
  }

  Future<void> _scheduleDailyMorningNotification({String? teaser}) async {
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
      8, // 05:00
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 
                     user?.userMetadata?['name'] as String?;
    final firstName = (fullName != null && fullName.trim().isNotEmpty) 
        ? fullName.trim().split(' ').first 
        : null;

    final title = firstName != null 
        ? '✨ $firstName, your style idea is ready!' 
        : '✨ Your style idea for today';

    // Use pre-generated teaser, cached teaser, or fallback
    String body = teaser ?? _defaultBody;
    if (teaser == null) {
      final prefs = await SharedPreferences.getInstance();
      body = prefs.getString(_teaserKey) ?? _defaultBody;
    }

    await _plugin.zonedSchedule(
      _morningNotificationId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
      try {
        // Pre-generate teaser in background, don't block scheduling
        final teaser = await _preGenerateTeaser();
        await _scheduleDailyMorningNotification(teaser: teaser);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Restore morning notification failed: $e');
      }
    }
  }

  /// Pre-generates a personalised teaser by calling the today-suggestion AI.
  /// Caches the result in SharedPreferences for the next notification.
  Future<String?> _preGenerateTeaser() async {
    try {
      final weatherService = WeatherService();
      final styleService = StyleService();
      final todaySuggestionService = TodaySuggestionService();

      // Fetch data concurrently — fail gracefully if any call errors
      final results = await Future.wait([
        weatherService.getCurrentWeather().catchError((_) => <String, dynamic>{}),
        styleService.fetchQuizResult().catchError((_) => null),
        styleService.fetchUpcomingEvents().catchError((_) => <Map<String, dynamic>>[]),
      ]).timeout(const Duration(seconds: 8), onTimeout: () => [{}, null, []]);

      final weather = results[0] as Map<String, dynamic>;
      final quizResult = results[1] as Map<String, dynamic>?;
      final events = results[2] as List<Map<String, dynamic>>;
      final nextEvent = events.isNotEmpty ? events.first : null;

      final suggestion = await todaySuggestionService.fetchTodaySuggestion(
        weather: weather,
        quizResult: quizResult,
        nextEvent: nextEvent,
      );

      if (suggestion != null) {
        final description = suggestion['description'] as String? ?? '';
        final stylingNote = suggestion['styling_note'] as String? ?? '';
        // Prefer the description, append styling note if short
        String teaser = description;
        if (teaser.isEmpty && stylingNote.isNotEmpty) {
          teaser = stylingNote;
        } else if (teaser.length < 60 && stylingNote.isNotEmpty) {
          teaser = '$teaser $stylingNote';
        }

        if (teaser.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_teaserKey, teaser);
          if (kDebugMode) debugPrint('✅ Notification teaser cached: $teaser');
          return teaser;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Teaser pre-generation failed: $e');
    }
    return null;
  }
}
