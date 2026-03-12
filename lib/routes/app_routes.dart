import 'package:flutter/material.dart';
import '../presentation/smart_suggestions/smart_suggestions.dart';
import '../presentation/learning_paths/learning_paths.dart';
import '../presentation/outfit_capture_flow/outfit_capture_flow.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/add_clothing_item/add_clothing_item.dart';
import '../presentation/wardrobe_management/wardrobe_management.dart';
import '../presentation/welcome_philosophy/welcome_philosophy.dart';
import '../presentation/feature_overview/feature_overview.dart';
import '../presentation/personalization_setup/personalization_setup.dart';
import '../presentation/daily_log/daily_log.dart';
import '../presentation/outfit_rating/outfit_rating.dart';
import '../presentation/insights_dashboard/insights_dashboard.dart';
import '../presentation/purchase_tracking/purchase_tracking.dart';
import '../presentation/settings_profile/settings_profile.dart';
import '../presentation/premium_upgrade/premium_upgrade.dart';
import '../presentation/ai_intelligence/ai_intelligence.dart';
import '../presentation/personal_progress_dashboard/personal_progress_dashboard.dart';
import '../presentation/challenge_center/challenge_center.dart';
import '../presentation/achievement_gallery/achievement_gallery.dart';
import '../presentation/home_screen/home_screen.dart';

/// App Routes - Centralized navigation configuration for Everywear
/// 
/// Navigation Structure (Updated):
/// - Bottom Nav: 5 tabs (Today, Wardrobe, Style, Purchases, Profile)
/// - Insights: Moved to Profile screen for cleaner navigation
/// - Secondary screens accessed via pushNamed
class AppRoutes {
  AppRoutes._();

  // ============================================
  // MAIN NAVIGATION ROUTES (Bottom Bar)
  // ============================================
  static const String initial = '/';
  static const String home = '/home';
  
  // Primary tabs (indexes 0-4)
  static const String dailyLog = '/daily-log';
  static const String wardrobeManagement = '/wardrobe-management';
  static const String smartSuggestions = '/smart-suggestions';
  static const String purchaseTracking = '/purchase-tracking';
  static const String settingsProfile = '/settings-profile';

  // ============================================
  // INSIGHTS & ANALYTICS (Secondary navigation)
  // ============================================
  static const String insightsDashboard = '/insights-dashboard';
  static const String personalProgressDashboard = '/personal-progress-dashboard';
  static const String achievementGallery = '/achievement-gallery';

  // ============================================
  // ONBOARDING & SETUP
  // ============================================
  static const String splash = '/splash-screen';
  static const String welcomePhilosophy = '/welcome-philosophy';
  static const String featureOverview = '/feature-overview';
  static const String personalizationSetup = '/personalization-setup';

  // ============================================
  // WARDROBE OPERATIONS
  // ============================================
  static const String addClothingItem = '/add-clothing-item';
  static const String outfitCaptureFlow = '/outfit-capture-flow';
  static const String outfitRating = '/outfit-rating';

  // ============================================
  // AI & INTELLIGENCE
  // ============================================
  static const String aiIntelligence = '/ai-intelligence';
  static const String learningPaths = '/learning-paths';
  static const String challengeCenter = '/challenge-center';

  // ============================================
  // PREMIUM & BILLING
  // ============================================
  static const String premiumUpgrade = '/premium-upgrade';
  static const String subscription = '/premium-upgrade';

  // ============================================
  // PROFILE ACTIONS
  // ============================================
  static const String editProfile = '/settings-profile';
  static const String changePassword = '/settings-profile';
  static const String helpCenter = '/settings-profile';
  static const String sendFeedback = '/settings-profile';

  // ============================================
  // ROUTE MAP
  // ============================================
  static Map<String, WidgetBuilder> routes = {
    // Main navigation
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    
    // Primary tabs
    dailyLog: (context) => const DailyLog(),
    wardrobeManagement: (context) => const WardrobeManagement(),
    smartSuggestions: (context) => const SmartSuggestions(),
    purchaseTracking: (context) => const PurchaseTracking(),
    settingsProfile: (context) => const SettingsProfile(),

    // Insights & Analytics (accessed from Profile)
    insightsDashboard: (context) => const InsightsDashboard(),
    personalProgressDashboard: (context) => const PersonalProgressDashboard(),
    achievementGallery: (context) => const AchievementGallery(),

    // Onboarding
    splash: (context) => const SplashScreen(),
    welcomePhilosophy: (context) => const WelcomePhilosophy(),
    featureOverview: (context) => const FeatureOverview(),
    personalizationSetup: (context) => const PersonalizationSetup(),

    // Wardrobe operations
    addClothingItem: (context) => const AddClothingItem(),
    outfitCaptureFlow: (context) => const OutfitCaptureFlow(),
    outfitRating: (context) => const OutfitRating(),

    // AI & Intelligence
    aiIntelligence: (context) => const AIIntelligence(),
    learningPaths: (context) => const LearningPaths(),
    challengeCenter: (context) => const ChallengeCenter(),

    // Premium
    premiumUpgrade: (context) => const PremiumUpgrade(),
  };

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get route name for bottom nav index
  static String getBottomNavRoute(int index) {
    switch (index) {
      case 0:
        return dailyLog;
      case 1:
        return wardrobeManagement;
      case 2:
        return smartSuggestions;
      case 3:
        return purchaseTracking;
      case 4:
        return settingsProfile;
      default:
        return home;
    }
  }

  /// Get bottom nav index for a route
  static int getBottomNavIndex(String route) {
    switch (route) {
      case dailyLog:
        return 0;
      case wardrobeManagement:
        return 1;
      case smartSuggestions:
        return 2;
      case purchaseTracking:
        return 3;
      case settingsProfile:
        return 4;
      default:
        return 0;
    }
  }
}
