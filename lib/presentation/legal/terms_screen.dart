import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

    return Scaffold(
      appBar: const CustomAppBar(title: "Terms of Use"),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Everywear Terms",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 3.h),

            _section(
              theme,
              "Use of the app",
              "Everywear provides tools to organize wardrobes "
              "and track outfits. By using the app you agree "
              "to use the service responsibly.",
            ),

            _section(
              theme,
              "Accounts",
              "You are responsible for maintaining the confidentiality "
              "of your account credentials.",
            ),

            _section(
              theme,
              "Essential & Signature",
              "Everywear offers two tiers:\n\n"
              "Essential — free access to core wardrobe tools.\n\n"
              "Signature — premium access to advanced insights, "
              "analytics and enhanced outfit suggestions.",
            ),

            _section(
              theme,
              "Subscriptions",
              "Subscriptions renew automatically unless cancelled "
              "through your App Store or Google Play account.",
            ),

            _section(
              theme,
              "Cancellation",
              "You may cancel your subscription anytime through "
              "your store account settings.",
            ),

            _section(
              theme,
              "User content",
              "You retain ownership of wardrobe photos and data "
              "you upload. Everywear stores this data only "
              "to provide the service.",
            ),

            _section(
              theme,
              "Contact",
              "Questions regarding these terms:\n\n"
              "support@everywear.studio",
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
