import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './ai_intelligence_service.dart';
import './local_database_service.dart';
import './notification_service.dart';

/// Clears data that belongs to one authenticated account without touching
/// device-wide choices such as locale, theme, or crash-reporting consent.
class AccountStateService {
  AccountStateService._();

  static Future<void> clearForUser(String userId) async {
    AIIntelligenceService.instance.clearCache();
    await NotificationService.instance.clearUserState(userId);

    try {
      await LocalDatabaseService().clearCurrentUser();
    } catch (error) {
      if (kDebugMode)
        debugPrint('Unable to clear local wardrobe cache: $error');
    }

    final prefs = await SharedPreferences.getInstance();
    const accountKeys = [
      'selectedStyles',
      'workEnvironment',
      'socialFrequency',
      'climate',
      'purchaseFrequency',
      'budgetConsciousness',
      'environmentalImpact',
    ];
    for (final key in accountKeys) {
      await prefs.remove('$userId:$key');
      // Remove legacy unscoped values so they cannot leak to another account.
      await prefs.remove(key);
    }
    await prefs.remove('hasSeenOnboarding:$userId');
    await prefs.remove('hasSeenOnboarding');
  }
}
