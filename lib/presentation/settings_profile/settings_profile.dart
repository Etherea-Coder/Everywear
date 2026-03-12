import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/app_export.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/locale_manager.dart';
import '../../routes/app_routes.dart';
import '../../main.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/confirmation_dialog_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_tile_widget.dart';
import './widgets/theme_selector_dialog.dart';

class SettingsProfile extends ConsumerStatefulWidget {
  const SettingsProfile({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsProfile> createState() => _SettingsProfileState();
}

class _SettingsProfileState extends ConsumerState<SettingsProfile> {
  bool _morningAISuggestions = true;
  bool _analyticsOptIn = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    // ⚠️ Adjust `currentUserProvider` to match your actual auth provider
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: localizations.settingsAndProfile,
        variant: CustomAppBarVariant.standard,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfileHeaderWidget(
              name: user?.displayName ?? '',
              email: user?.email ?? '',
              avatarUrl: user?.photoURL ?? '',
              membershipTier: user?.membershipTier ?? 'Free',
              onEditProfile: _handleEditProfile,
            ),
            SizedBox(height: 2.h),

            _buildSection(
              title: 'General',
              children: [
                _buildNavTile(
                  icon: Icons.palette_outlined,
                  title: localizations.theme,
                  subtitle: _getThemeLabel(
                    ref.watch(themeModeProvider).toString().split('.').last,
                    localizations,
                  ),
                  onTap: () => _showThemeSelector(context),
                ),
                _buildNavTile(
                  icon: Icons.language_outlined,
                  title: localizations.language,
                  subtitle: LocaleManager.getLanguageDisplayName(
                    ref.watch(localeProvider).languageCode,
                  ),
                  onTap: () => _showLanguageSelector(context),
                ),
                _buildSwitchTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Morning AI suggestions',
                  subtitle: 'Daily outfit ideas every morning',
                  value: _morningAISuggestions,
                  onChanged: (value) =>
                      setState(() => _morningAISuggestions = value),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            _buildSection(
              title: localizations.accountSettings,
              children: [
                _buildNavTile(
                  icon: Icons.lock_outline,
                  title: localizations.changePassword,
                  subtitle: localizations.updatePassword,
                  onTap: _handleChangePassword,
                ),
                _buildNavTile(
                  icon: Icons.delete_outline,
                  title: localizations.deleteAccount,
                  subtitle: localizations.permanentlyDeleteAccount,
                  titleColor: theme.colorScheme.error,
                  onTap: () => _showDeleteAccountConfirmation(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            _buildSection(
              title: localizations.privacySettings,
              children: [
                _buildSwitchTile(
                  icon: Icons.analytics_outlined,
                  title: localizations.analytics,
                  subtitle: localizations.helpImproveApp,
                  value: _analyticsOptIn,
                  onChanged: (value) =>
                      setState(() => _analyticsOptIn = value),
                ),
                _buildNavTile(
                  icon: Icons.download_outlined,
                  title: localizations.exportData,
                  subtitle: localizations.downloadWardrobeData,
                  onTap: () => _showExportOptions(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            _buildSection(
              title: localizations.subscription,
              children: [
                _buildNavTile(
                  icon: Icons.card_membership,
                  title: localizations.currentPlan,
                  subtitle: user?.membershipTier ?? 'Free',
                  onTap: _handleViewSubscription,
                ),
                _buildNavTile(
                  icon: Icons.upgrade,
                  title: localizations.upgradePlan,
                  subtitle: localizations.unlockMoreFeatures,
                  onTap: _handleUpgradePlan,
                ),
              ],
            ),
            SizedBox(height: 2.h),

            _buildSection(
              title: localizations.helpAndSupport,
              children: [
                _buildNavTile(
                  icon: Icons.help_outline,
                  title: localizations.helpCenter,
                  subtitle: localizations.faqsAndGuides,
                  onTap: _handleHelpCenter,
                ),
                _buildNavTile(
                  icon: Icons.feedback_outlined,
                  title: localizations.sendFeedback,
                  subtitle: localizations.shareYourThoughts,
                  onTap: _handleSendFeedback,
                ),
              ],
            ),
            SizedBox(height: 3.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context, localizations),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: 1.5.h),

            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  // ─── Section & Tile Builders ──────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return SettingsSectionWidget(title: title, children: children);
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return SettingsTileWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      titleColor: titleColor,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsTileWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // ─── Theme ────────────────────────────────────────────────────────────────

  String _getThemeLabel(String theme, AppLocalizations localizations) {
    switch (theme) {
      case 'light':
        return localizations.lightMode;
      case 'dark':
        return localizations.darkMode;
      case 'auto':
        return localizations.autoSystem;
      default:
        return localizations.lightMode;
    }
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ThemeSelectorDialog(
        currentTheme:
            ref.watch(themeModeProvider).toString().split('.').last,
        onThemeSelected: _applyThemeMode,
      ),
    );
  }

  void _applyThemeMode(String themeMode) async {
    final mode = themeMode == 'dark'
        ? ThemeMode.dark
        : themeMode == 'auto'
            ? ThemeMode.system
            : ThemeMode.light;

    await ref.read(settingsNotifierProvider.notifier).updateTheme(mode);

    if (mounted) {
      MyApp.of(context)?.updateThemeMode(themeMode);
    }
  }

  // ─── Language ─────────────────────────────────────────────────────────────

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

        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.selectLanguage,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              ...languages.map((lang) {
                final code = lang['code']!;
                final name = lang['name']!;
                final isSelected =
                    ref.watch(localeProvider).languageCode == code;

                return ListTile(
                  leading: Text(
                    LocaleManager.getLanguageFlag(code),
                    style: TextStyle(fontSize: 24.sp),
                  ),
                  title: Text(name),
                  trailing:
                      isSelected ? const Icon(Icons.check_circle) : null,
                  onTap: () {
                    final newLocale = Locale(code);
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .updateLocale(newLocale);
                    MyApp.of(context)?.updateLocale(newLocale);
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

  // ─── Account ──────────────────────────────────────────────────────────────

  void _handleEditProfile() {
    Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  void _handleChangePassword() {
    Navigator.pushNamed(context, AppRoutes.changePassword);
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
    // TODO: wire to auth delete
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion initiated')),
    );
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  void _showExportOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.exportDataFormat,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(localizations.pdfReport),
              subtitle: Text(localizations.comprehensiveWardrobeReport),
              onTap: () {
                Navigator.pop(context);
                _handleExportData('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(localizations.csvSpreadsheet),
              subtitle: Text(localizations.rawDataAnalysis),
              onTap: () {
                Navigator.pop(context);
                _handleExportData('CSV');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleExportData(String format) {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${localizations.exportingData} $format...')),
    );
  }

  // ─── Subscription ─────────────────────────────────────────────────────────

  void _handleViewSubscription() {
    Navigator.pushNamed(context, AppRoutes.subscription);
  }

  void _handleUpgradePlan() {
    Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
  }

  // ─── Help ─────────────────────────────────────────────────────────────────

  void _handleHelpCenter() {
    Navigator.pushNamed(context, AppRoutes.helpCenter);
  }

  void _handleSendFeedback() {
    Navigator.pushNamed(context, AppRoutes.sendFeedback);
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  void _handleLogout(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialogWidget(
        title: localizations.logout,
        message: localizations.logoutConfirmation,
        confirmText: localizations.logout,
        cancelText: localizations.cancel,
        isDestructive: false,
        onConfirm: () {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/splash-screen', (route) => false);
        },
      ),
    );
  }
}
