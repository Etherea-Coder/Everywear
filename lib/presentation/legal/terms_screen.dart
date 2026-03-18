import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_localizations.dart';
import '../../widgets/custom_app_bar.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

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
        title: l10n.termsOfService,
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.termsTitle,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3.h),
            _section(
              theme,
              l10n.termsUseTitle,
              l10n.termsUseContent,
            ),
            _section(
              theme,
              l10n.termsAccountsTitle,
              l10n.termsAccountsContent,
            ),
            _section(
              theme,
              l10n.termsTiersTitle,
              l10n.termsTiersContent,
            ),
            _section(
              theme,
              l10n.termsSubscriptionsTitle,
              l10n.termsSubscriptionsContent,
            ),
            _section(
              theme,
              l10n.termsCancellationTitle,
              l10n.termsCancellationContent,
            ),
            _section(
              theme,
              l10n.termsUserContentTitle,
              l10n.termsUserContentContent,
            ),
            _section(
              theme,
              l10n.termsContactTitle,
              l10n.termsContactContent,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}