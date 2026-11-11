import 'package:flutter/foundation.dart';

import './account_state_service.dart';
import './analytics_service.dart';
import './revenuecat_service.dart';
import './supabase_service.dart';

/// Coordinates local account cleanup and provider identity when ending a
/// Supabase session.
class AuthSessionService {
  AuthSessionService._();

  static Future<void> signOutCurrentUser() async {
    if (!SupabaseService.isInitialized) return;
    final client = SupabaseService.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId != null) {
      try {
        await AccountStateService.clearForUser(userId);
      } catch (_) {
        if (kDebugMode) debugPrint('Account cache cleanup failed on sign-out');
      }
    }
    try {
      await AnalyticsService.instance.resetUser();
    } catch (_) {
      if (kDebugMode) debugPrint('Analytics identity cleanup failed');
    }

    // RevenueCat must observe the Supabase signed-out state before logging out;
    // otherwise its guard re-binds the still-current user.
    await client.auth.signOut();
    await RevenueCatService.logOut();
  }
}
