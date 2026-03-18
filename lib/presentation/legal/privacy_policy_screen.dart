import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_localizations.dart';
import '../../widgets/custom_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  Widget _section(
    ThemeData theme,
    String title,
    String content,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 1.h),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.privacyPolicy, // Already exists
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyTitle,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              l10n.privacyLastUpdated,
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 3.h),
            _section(
              theme,
              l10n.privacyPhilosophyTitle,
              l10n.privacyPhilosophyContent,
            ),
            _section(
              theme,
              l10n.privacyCollectTitle,
              l10n.privacyCollectContent,
            ),
            _section(
              theme,
              l10n.privacyWardrobeTitle,
              l10n.privacyWardrobeContent,
            ),
            _section(
              theme,
              l10n.privacyAnalyticsTitle,
              l10n.privacyAnalyticsContent,
            ),
            _section(
              theme,
              l10n.privacySubscriptionsTitle,
              l10n.privacySubscriptionsContent,
            ),
            _section(
              theme,
              l10n.privacyRightsTitle,
              l10n.privacyRightsContent,
            ),
            _section(
              theme,
              l10n.privacyContactTitle,
              l10n.privacyContactContent,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}