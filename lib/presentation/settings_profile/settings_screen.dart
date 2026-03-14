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
import './widgets/settings_section_widget.dart';
import './widgets/settings_tile_widget.dart';
import './widgets/theme_selector_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _morningAISuggestions = true;
  bool _analyticsOptIn = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Settings',
        variant: CustomAppBarVariant.standard,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 2.h),

            // General
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

            // Account & Security
            _buildSection(
              title: localizations.accountSettings,
              children: [
                _buildNavTile(
                  icon: Icons.lock_outline,
                  title: localizations.changePassword,
                  subtitle: localizations.updatePassword,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.changePassword),
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

            // Privacy
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

            // Help
            _buildSection(
              title: localizations.helpAndSupport,
              children: [
                _buildNavTile(
                  icon: Icons.help_outline,
                  title: localizations.helpCenter,
                  subtitle: localizations.faqsAndGuides,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpCenter),
                ),
                _buildNavTile(
                  icon: Icons.feedback_outlined,
                  title: localizations.sendFeedback,
                  subtitle: localizations.shareYourThoughts,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.sendFeedback),
                ),
                _buildNavTile(
                  icon: Icons.policy_outlined,
                  title: localizations.privacyPolicy,
                  subtitle: localizations.viewPrivacyPolicy,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),
                _buildNavTile(
                  icon: Icons.description_outlined,
                  title: localizations.termsOfService,
                  subtitle: localizations.viewTermsOfService,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.terms),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Logout
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

            // Version
            Text(
              'Version 1.0.1',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
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
  }) =>
      SettingsSectionWidget(title: title, children: children);

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) =>
      SettingsTileWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        titleColor: titleColor,
        onTap: onTap,
      );

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SettingsTileWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
      );

  // ─── Theme ────────────────────────────────────────────────────────────────

  String _getThemeLabel(String theme, AppLocalizations localizations) {
    switch (theme) {
      case 'light': return localizations.lightMode;
      case 'dark':  return localizations.darkMode;
      case 'auto':  return localizations.autoSystem;
      default:      return localizations.lightMode;
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
    if (mounted) MyApp.of(context)?.updateThemeMode(themeMode);
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
              Text(localizations.selectLanguage,
                  style: TextStyle(
                      fontSize: 16.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              ...languages.map((lang) {
                final code = lang['code']!;
                final isSelected =
                    ref.watch(localeProvider).languageCode == code;
                return ListTile(
                  leading: Text(LocaleManager.getLanguageFlag(code),
                      style: TextStyle(fontSize: 24.sp)),
                  title: Text(lang['name']!),
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

  void _handleDeleteAccount() async {
    try {
      await Supabase.instance.client.auth.admin
          .deleteUser(Supabase.instance.client.auth.currentUser!.id);
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/splash-screen', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
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
            Text(localizations.exportDataFormat,
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w600)),
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
        onConfirm: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/splash-screen', (route) => false);
          }
        },
      ),
    );
  }
}
