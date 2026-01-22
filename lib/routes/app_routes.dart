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

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String smartSuggestions = '/smart-suggestions';
  static const String learningPaths = '/learning-paths';
  static const String outfitCaptureFlow = '/outfit-capture-flow';
  static const String splash = '/splash-screen';
  static const String addClothingItem = '/add-clothing-item';
  static const String wardrobeManagement = '/wardrobe-management';
  static const String welcomePhilosophy = '/welcome-philosophy';
  static const String featureOverview = '/feature-overview';
  static const String personalizationSetup = '/personalization-setup';
  static const String dailyLog = '/daily-log';
  static const String outfitRating = '/outfit-rating';
  static const String insightsDashboard = '/insights-dashboard';
  static const String purchaseTracking = '/purchase-tracking';
  static const String settingsProfile = '/settings-profile';
  static const String premiumUpgrade = '/premium-upgrade';
  static const String aiIntelligence = '/ai-intelligence';
  static const String personalProgressDashboard =
      '/personal-progress-dashboard';
  static const String challengeCenter = '/challenge-center';
  static const String achievementGallery = '/achievement-gallery';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    smartSuggestions: (context) => const SmartSuggestions(),
    learningPaths: (context) => const LearningPaths(),
    outfitCaptureFlow: (context) => const OutfitCaptureFlow(),
    splash: (context) => const SplashScreen(),
    addClothingItem: (context) => const AddClothingItem(),
    wardrobeManagement: (context) => const WardrobeManagement(),
    welcomePhilosophy: (context) => const WelcomePhilosophy(),
    featureOverview: (context) => const FeatureOverview(),
    personalizationSetup: (context) => const PersonalizationSetup(),
    dailyLog: (context) => const DailyLog(),
    outfitRating: (context) => const OutfitRating(),
    insightsDashboard: (context) => const InsightsDashboard(),
    purchaseTracking: (context) => const PurchaseTracking(),
    settingsProfile: (context) => const SettingsProfile(),
    premiumUpgrade: (context) => const PremiumUpgrade(),
    aiIntelligence: (context) => const AIIntelligence(),
    personalProgressDashboard: (context) => const PersonalProgressDashboard(),
    challengeCenter: (context) => const ChallengeCenter(),
    achievementGallery: (context) => const AchievementGallery(),
    // TODO: Add your other routes here
  };
}
