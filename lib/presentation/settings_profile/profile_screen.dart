import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/app_export.dart';
import '../../core/utils/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_tile_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user = ref.watch(supabaseAuthProvider).value;
    final profileAsync = ref.watch(userProfileProvider);

    final displayName = user?.userMetadata?['full_name'] ?? user?.email ?? '';
    final email = user?.email ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] ?? '';
    final membershipTier = profileAsync.value?['membership_tier'] ?? 'Free';
    
    // Map tier to display name
    String getDisplayTier(String tier) {
      switch (tier.toLowerCase()) {
        case 'free':
          return 'Essential';
        case 'premium':
          return 'Signature';
        case 'pro':
          return 'Signature';
        default:
          return tier;
      }
    }
    final displayTier = getDisplayTier(membershipTier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: l10n.profileTitle,
        variant: CustomAppBarVariant.standard,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeaderWidget(
              name: displayName,
              email: email,
              avatarUrl: avatarUrl,
              membershipTier: membershipTier,
              onEditProfile: () =>
                  Navigator.pushNamed(context, AppRoutes.editProfile),
            ),
            SizedBox(height: 2.h),

            SettingsSectionWidget(
              title: l10n.insightsAnalytics,
              children: [
                SettingsTileWidget(
                  icon: Icons.insights_outlined,
                  title: l10n.styleInsights,
                  subtitle: l10n.styleInsightsSubtitle,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.insightsDashboard),
                ),
                SettingsTileWidget(
                  icon: Icons.emoji_events_outlined,
                  title: l10n.achievements,
                  subtitle: l10n.achievementsSubtitle,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.achievementGallery),
                ),
                SettingsTileWidget(
                  icon: Icons.trending_up_outlined,
                  title: l10n.progressDashboard,
                  subtitle: l10n.progressDashboardSubtitle,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.personalProgressDashboard,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            SettingsSectionWidget(
              title: l10n.subscription,
              children: [
                SettingsTileWidget(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.membership,
                  subtitle: membershipTier.toLowerCase() == 'free'
                      ? l10n.essentialPlanUnlock
                      : '$displayTier ${l10n.plan}',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            SettingsSectionWidget(
              title: '',
              children: [
                SettingsTileWidget(
                  icon: Icons.settings_outlined,
                  title: l10n.settings,
                  subtitle: l10n.settingsSubtitle,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                ),
              ],
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }
}