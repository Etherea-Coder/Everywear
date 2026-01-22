import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/locale_manager.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/confirmation_dialog_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_tile_widget.dart';
import './widgets/theme_selector_dialog.dart';

/// Settings Profile Screen - Comprehensive user account management and app customization
/// Provides organized sections for profile management, preferences, privacy, and data control
class SettingsProfile extends ConsumerStatefulWidget {
  const SettingsProfile({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsProfile> createState() => _SettingsProfileState();
}

class _SettingsProfileState extends ConsumerState<SettingsProfile> {
  // User profile data (mock)
  final Map<String, dynamic> _userProfile = {
    'name': 'Sarah Mitchell',
    'email': 'sarah.mitchell@email.com',
    'avatarUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
    'membershipTier': 'Premium',
    'joinDate': '2025-06-15',
  };

  // App preferences
  bool _emailNotifications = false;
  bool _twoFactorAuth = true;
  bool _dataSharing = false;
  bool _analyticsOptIn = true;
  String _measurementUnit = 'metric';

  // Subscription data (mock)
  final Map<String, dynamic> _subscriptionData = {
    'plan': 'Premium',
    'price': '\$9.99/month',
    'nextBilling': '2026-02-12',
    'features': [
      'Unlimited wardrobe items',
      'AI insights',
      'Export data',
      'Priority support',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  /// Load saved settings from persistent storage (deprecated for providers)
  Future<void> _loadSavedSettings() async {
    // Current theme and locale are already managed by providers synced in MyApp
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: localizations.settingsAndProfile,
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeaderWidget(
              name: _userProfile['name'],
              email: _userProfile['email'],
              avatarUrl: _userProfile['avatarUrl'],
              membershipTier: _userProfile['membershipTier'],
              onEditProfile: _handleEditProfile,
            ),
            SizedBox(height: 2.h),
            SettingsSectionWidget(
              title: localizations.accountSettings,
              children: [
                SettingsTileWidget(
                  icon: Icons.lock_outline,
                  title: localizations.changePassword,
                  subtitle: localizations.updatePassword,
                  onTap: _handleChangePassword,
                ),
                SettingsTileWidget(
                  icon: Icons.email_outlined,
                  title: localizations.emailPreferences,
                  subtitle: localizations.manageEmailNotifications,
                  trailing: Switch(
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ),
                SettingsTileWidget(
                  icon: Icons.security,
                  title: localizations.twoFactorAuth,
                  subtitle: _twoFactorAuth
                      ? localizations.enabled
                      : localizations.disabled,
                  trailing: Switch(
                    value: _twoFactorAuth,
                    onChanged: (value) {
                      setState(() => _twoFactorAuth = value);
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SettingsSectionWidget(
              title: localizations.appPreferences,
              children: [
                SettingsTileWidget(
                  icon: Icons.palette_outlined,
                  title: localizations.theme,
                  subtitle: _getThemeLabel(ref.watch(themeModeProvider).toString().split('.').last, localizations),
                  onTap: () => _showThemeSelector(context),
                ),
                SettingsTileWidget(
                  icon: Icons.notifications_outlined,
                  title: localizations.notifications,
                  subtitle: localizations.manageNotifications,
                  onTap: () {},
                ),
                SettingsTileWidget(
                  icon: Icons.language_outlined,
                  title: localizations.language,
                  subtitle: LocaleManager.getLanguageDisplayName(
                    ref.watch(localeProvider).languageCode,
                  ),
                  onTap: () => _showLanguageSelector(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SettingsSectionWidget(
              title: localizations.privacySettings,
              children: [
                SettingsTileWidget(
                  icon: Icons.share_outlined,
                  title: localizations.dataSharing,
                  subtitle: localizations.shareUsageData,
                  trailing: Switch(
                    value: _dataSharing,
                    onChanged: (value) {
                      setState(() => _dataSharing = value);
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ),
                SettingsTileWidget(
                  icon: Icons.analytics_outlined,
                  title: localizations.analytics,
                  subtitle: localizations.helpImproveApp,
                  trailing: Switch(
                    value: _analyticsOptIn,
                    onChanged: (value) {
                      setState(() => _analyticsOptIn = value);
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ),
                SettingsTileWidget(
                  icon: Icons.visibility_outlined,
                  title: localizations.profileVisibility,
                  subtitle: localizations.manageProfileVisibility,
                  onTap: _handleVisibilitySettings,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SettingsSectionWidget(
              title: localizations.dataManagement,
              children: [
                SettingsTileWidget(
                  icon: Icons.download_outlined,
                  title: localizations.exportData,
                  subtitle: localizations.downloadWardrobeData,
                  onTap: () => _showExportOptions(context),
                ),
                SettingsTileWidget(
                  icon: Icons.backup_outlined,
                  title: localizations.backupSettings,
                  subtitle: localizations.automaticCloudBackup,
                  onTap: _handleBackupSettings,
                ),
                SettingsTileWidget(
                  icon: Icons.delete_outline,
                  title: localizations.deleteAccount,
                  subtitle: localizations.permanentlyDeleteAccount,
                  titleColor: theme.colorScheme.error,
                  onTap: () => _showDeleteAccountConfirmation(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SettingsSectionWidget(
              title: localizations.subscription,
              children: [
                SettingsTileWidget(
                  icon: Icons.card_membership,
                  title: localizations.currentPlan,
                  subtitle:
                      '${_subscriptionData['plan']} - ${_subscriptionData['price']}',
                  onTap: _handleViewSubscription,
                ),
                SettingsTileWidget(
                  icon: Icons.receipt_long,
                  title: localizations.billingHistory,
                  subtitle: localizations.viewPastInvoices,
                  onTap: _handleBillingHistory,
                ),
                SettingsTileWidget(
                  icon: Icons.upgrade,
                  title: localizations.upgradePlan,
                  subtitle: localizations.unlockMoreFeatures,
                  onTap: _handleUpgradePlan,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SettingsSectionWidget(
              title: localizations.helpAndSupport,
              children: [
                SettingsTileWidget(
                  icon: Icons.help_outline,
                  title: localizations.helpCenter,
                  subtitle: localizations.faqs_and_guides,
                  onTap: _handleHelpCenter,
                ),
                SettingsTileWidget(
                  icon: Icons.feedback_outlined,
                  title: localizations.sendFeedback,
                  subtitle: localizations.shareYourThoughts,
                  onTap: _handleSendFeedback,
                ),
                SettingsTileWidget(
                  icon: Icons.info_outline,
                  title: localizations.about,
                  subtitle: localizations.version,
                  onTap: _handleAbout,
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    localizations.logout,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(String theme, AppLocalizations localizations) {
    switch (theme) {
      case 'light':
        return localizations.lightMode;
      case 'dark':
        return localizations.darkMode;
      case 'auto':
        return localizations.auto_system;
      default:
        return localizations.lightMode;
    }
  }

  void _handleEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile functionality coming soon')),
    );
  }

  void _handleChangePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password functionality coming soon'),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ThemeSelectorDialog(
        currentTheme: ref.watch(themeModeProvider).toString().split('.').last,
        onThemeSelected: (theme) {
          _applyThemeMode(theme);
        },
      ),
    );
  }

  void _applyThemeMode(String themeMode) async {
    final mode = themeMode == 'dark' ? ThemeMode.dark : (themeMode == 'auto' ? ThemeMode.system : ThemeMode.light);
    await ref.read(settingsNotifierProvider.notifier).updateTheme(mode);

    // Apply theme to entire app by updating MyApp state
    if (mounted) {
      final myAppState = MyApp.of(context);
      if (myAppState != null) {
        myAppState.updateThemeMode(themeMode);
      }
    }
  }

  void _toggleMeasurementUnit() {
    setState(() {
      _measurementUnit = _measurementUnit == 'metric' ? 'imperial' : 'metric';
    });
  }

  void _showLanguageSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        final languages = [
          {'code': 'en', 'name': localizations.english},
          {'code': 'es', 'name': localizations.spanish},
          {'code': 'fr', 'name': localizations.french},
        ];

        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.selectLanguage,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              ...languages.map((lang) {
                final languageCode = lang['code']!;
                final languageName = lang['name']!;
                final isSelected = _selectedLanguage == languageCode;

                return ListTile(
                  leading: Text(
                    LocaleManager.getLanguageFlag(languageCode),
                    style: TextStyle(fontSize: 24.sp),
                  ),
                  title: Text(languageName),
                  trailing: isSelected ? const Icon(Icons.check_circle) : null,
                  onTap: () {
                    final newLocale = Locale(languageCode);
                    ref.read(settingsNotifierProvider.notifier).updateLocale(newLocale);

                    // Apply language immediately by updating the parent MyApp state
                    final myAppState = MyApp.of(context);
                    if (myAppState != null) {
                      myAppState.updateLocale(newLocale);
                    }

                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _handleVisibilitySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visibility settings coming soon')),
    );
  }

  void _showExportOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.exportDataFormat,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(localizations.pdfReport),
                subtitle: Text(localizations.comprehensive_wardrobe_report),
                onTap: () {
                  Navigator.pop(context);
                  _handleExportData('PDF');
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(localizations.csvSpreadsheet),
                subtitle: Text(localizations.raw_data_analysis),
                onTap: () {
                  Navigator.pop(context);
                  _handleExportData('CSV');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleExportData(String format) {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${localizations.exportingData} $format...')));
  }

  void _handleBackupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup settings coming soon')),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialogWidget(
        title: localizations.deleteAccount,
        message: localizations.deleteAccountConfirmation,
        confirmText: localizations.delete,
        cancelText: localizations.cancel,
        isDestructive: true,
        onConfirm: _handleDeleteAccount,
      ),
    );
  }

  void _handleDeleteAccount() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account deletion initiated')));
  }

  void _handleViewSubscription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription details coming soon')),
    );
  }

  void _handleBillingHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Billing history coming soon')),
    );
  }

  void _handleUpgradePlan() {
    Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
  }

  void _handleHelpCenter() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Help center coming soon')));
  }

  void _handleSendFeedback() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback form coming soon')));
  }

  void _handleAbout() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.about),
        content: Text(
          '${localizations.appName} - ${localizations.about_everywear}\n\n${localizations.version}\n© 2026 ${localizations.appName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialogWidget(
        title: localizations.logout,
        message: localizations.logout_confirmation,
        confirmText: localizations.logout,
        cancelText: localizations.cancel,
        isDestructive: false,
        onConfirm: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/splash-screen', (route) => false);
        },
      ),
    );
  }
}
