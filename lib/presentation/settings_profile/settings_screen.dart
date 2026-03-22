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
import '../../../presentation/settings_profile/widgets/reset_app_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/export_service.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _morningAISuggestions = false;
  bool _analyticsOptIn = true;

  bool _isEmailUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    final identities = user.identities ?? [];
    if (identities.isEmpty) {
      // Fall back to app_metadata
      final provider = user.appMetadata['provider'] as String?;
      return provider == 'email';
    }
    
    // Check if ANY identity is NOT google/oauth
    return identities.any((i) => 
      i.provider == 'email' || 
      i.provider == 'username' ||
      (!['google', 'github', 'facebook', 'apple', 'twitter'].contains(i.provider))
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await NotificationService.instance.initialize(); // ← add this
    final notifications =
        await NotificationService.instance.isMorningSuggestionsEnabled();
    final analytics = await AnalyticsService.instance.isAnalyticsEnabled();
    if (mounted) {
      setState(() {
        _morningAISuggestions = notifications;
        _analyticsOptIn = analytics;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: localizations.settings,
        variant: CustomAppBarVariant.standard,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 2.h),

            // ── General ──────────────────────────────────────────────────
            _buildSection(
              title: localizations.translate('general'),
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
                  title: localizations.morningAiSuggestions,
                  subtitle: localizations.dailyOutfitIdeas,
                  value: _morningAISuggestions,
                  onChanged: (value) async {
                    if (value) {
                      final granted =
                          await NotificationService.instance.enableMorningSuggestions();
                      if (!granted && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enable notifications in your device settings.'),
                          ),
                        );
                        return;
                      }
                    } else {
                      await NotificationService.instance.disableMorningSuggestions();
                    }
                    if (mounted) setState(() => _morningAISuggestions = value);
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // ── Account & Security ───────────────────────────────────────
            _buildSection(
              title: localizations.accountSettings,
              children: [
                if (_isEmailUser())
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

            // ── Privacy ──────────────────────────────────────────────────
            _buildSection(
              title: localizations.privacySettings,
              children: [
                _buildSwitchTile(
                  icon: Icons.analytics_outlined,
                  title: localizations.analytics,
                  subtitle: localizations.helpImproveApp,
                  value: _analyticsOptIn,
                  onChanged: (value) async {
                    await AnalyticsService.instance.setAnalyticsEnabled(value);
                    if (mounted) setState(() => _analyticsOptIn = value);
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // ── Data Management ──────────────────────────────────────────
            _buildSection(
              title: localizations.dataManagement,
              children: [
                _buildNavTile(
                  icon: Icons.download_outlined,
                  title: localizations.exportData,
                  subtitle: localizations.downloadWardrobeData,
                  onTap: () => _showExportOptions(context),
                ),
                _buildNavTile(
                  icon: Icons.restart_alt_outlined,
                  title: localizations.translate('reset_app'),
                  subtitle: localizations.translate('reset_app_subtitle'),
                  titleColor: theme.colorScheme.error,
                  onTap: () => ResetAppDialog.show(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // ── Help & Support ───────────────────────────────────────────
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

            // ── Logout button ────────────────────────────────────────────
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

            // ── Version ──────────────────────────────────────────────────
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
    required Function(bool) onChanged,
  }) =>
      SettingsTileWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
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
      case 'system':
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
      isScrollControlled: true,
      builder: (context) {
        final languages = [
          {'code': 'en', 'name': localizations.english},
          {'code': 'es', 'name': localizations.spanish},
          {'code': 'fr', 'name': localizations.french},
        ];
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
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
            ),
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
      final response = await SupabaseService.instance.client.functions.invoke(
        'delete-account',
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Delete failed');
      }

      // Sign out locally after server-side deletion
      await SupabaseService.instance.client.auth.signOut();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/splash-screen', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
          ),
        );
      }
    }
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  void _showExportOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.25,
        maxChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
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
        ),
      ),
    );
  }

  void _handleExportData(String format) {
  if (format == 'PDF') {
    ExportService.instance.exportAsPDF(context);
  } else {
    ExportService.instance.exportAsCSV(context);
  }
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