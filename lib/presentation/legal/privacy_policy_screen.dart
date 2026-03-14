import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

    return Scaffold(
      appBar: const CustomAppBar(title: "Privacy Policy"),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Everywear Privacy Policy",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 1.h),

            Text(
              "Last updated: 2026",
              style: theme.textTheme.bodySmall,
            ),

            SizedBox(height: 3.h),

            _section(
              theme,
              "Our philosophy",
              "Everywear was designed as a calm wardrobe studio. "
              "Our goal is to help you rediscover the clothes you already own "
              "and develop your personal style intentionally. "
              "Your wardrobe data belongs to you.",
            ),

            _section(
              theme,
              "Information we collect",
              "When you create an account we may collect:\n\n"
              "• Email address\n"
              "• Authentication data\n"
              "• Basic device information\n\n"
              "This allows us to securely provide the service.",
            ),

            _section(
              theme,
              "Wardrobe data",
              "Everywear stores information you choose to add, such as:\n\n"
              "• Clothing items\n"
              "• Outfit logs\n"
              "• Wardrobe images\n"
              "• Style preferences\n\n"
              "This data is used only to provide wardrobe features.",
            ),

            _section(
              theme,
              "Analytics",
              "Anonymous usage data may be collected to understand how "
              "features are used and improve the application.",
            ),

            _section(
              theme,
              "Subscriptions",
              "Signature subscriptions are processed through "
              "Apple App Store or Google Play. "
              "Everywear never stores payment information.",
            ),

            _section(
              theme,
              "Your rights",
              "You may request:\n\n"
              "• account deletion\n"
              "• data export\n"
              "• support regarding your data",
            ),

            _section(
              theme,
              "Contact",
              "If you have privacy questions please contact:\n\n"
              "support@everywear.studio",
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
