import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../core/utils/app_localizations.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context);

  // Define FAQ items here (not as a class field)
  final List<Map<String, String>> faqItems = [
    {'question': l10n.faqQ1, 'answer': l10n.faqA1},
    {'question': l10n.faqQ2, 'answer': l10n.faqA2},
    {'question': l10n.faqQ3, 'answer': l10n.faqA3},
    {'question': l10n.faqQ4, 'answer': l10n.faqA4},
    {'question': l10n.faqQ5, 'answer': l10n.faqA5},
    {'question': l10n.faqQ6, 'answer': l10n.faqA6},
    {'question': l10n.faqQ7, 'answer': l10n.faqA7},
    {'question': l10n.faqQ8, 'answer': l10n.faqA8},
    {'question': l10n.faqQ9, 'answer': l10n.faqA9},
    {'question': l10n.faqQ10, 'answer': l10n.faqA10},
  ];

  return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: l10n.helpCenter, // Use localized title
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(theme, l10n),
            SizedBox(height: 1.5.h),
            _buildStudioIntro(theme, l10n),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: l10n.helpCenterPhilosophyTitle,
              icon: Icons.spa_outlined,
              child: _buildInfoCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpCenterPhilosophyHeading,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      l10n.helpCenterPhilosophyBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: l10n.helpCenterHowItWorksTitle,
              icon: Icons.auto_awesome_outlined,
              child: Column(
                children: [
                  _buildStepCard(
                    theme,
                    number: '1',
                    title: l10n.helpCenterStep1Title,
                    description: l10n.helpCenterStep1Desc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildStepCard(
                    theme,
                    number: '2',
                    title: l10n.helpCenterStep2Title,
                    description: l10n.helpCenterStep2Desc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildStepCard(
                    theme,
                    number: '3',
                    title: l10n.helpCenterStep3Title,
                    description: l10n.helpCenterStep3Desc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildStepCard(
                    theme,
                    number: '4',
                    title: l10n.helpCenterStep4Title,
                    description: l10n.helpCenterStep4Desc,
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.5.h),
            _buildProTipCard(theme, l10n),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: l10n.helpCenterPagesTitle,
              icon: Icons.dashboard_outlined,
              child: Column(
                children: [
                  _buildFeatureCard(
                    theme,
                    icon: Icons.today_outlined,
                    title: l10n.helpCenterPageTodayTitle,
                    description: l10n.helpCenterPageTodayDesc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.checkroom_outlined,
                    title: l10n.helpCenterPageWardrobeTitle,
                    description: l10n.helpCenterPageWardrobeDesc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.auto_awesome,
                    title: l10n.helpCenterPageStyleTitle,
                    description: l10n.helpCenterPageStyleDesc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.shopping_bag_outlined,
                    title: l10n.helpCenterPagePurchasesTitle,
                    description: l10n.helpCenterPagePurchasesDesc,
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.person_outline,
                    title: l10n.helpCenterPageProfileTitle,
                    description: l10n.helpCenterPageProfileDesc,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: l10n.helpCenterMembershipTitle,
              icon: Icons.workspace_premium_outlined,
              child: _buildInfoCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpCenterEssentialTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.6.h),
                    Text(
                      l10n.helpCenterEssentialDesc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      l10n.helpCenterSignatureTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.6.h),
                    Text(
                      l10n.helpCenterSignatureDesc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: l10n.helpCenterFaqTitle,
              icon: Icons.help_outline,
              child: _buildFaqList(theme, faqItems),
            ),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: l10n.helpCenterNeedHelpTitle,
              icon: Icons.mail_outline,
              child: _buildInfoCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpCenterNeedHelpBody1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    Text(
                      l10n.helpCenterNeedHelpBody2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.16),
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helpCenterHeroTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  l10n.helpCenterHeroSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioIntro(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          l10n.helpCenterStudioIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildProTipCard(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                l10n.helpCenterProTip,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStepCard(
    ThemeData theme, {
    required String number,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 11.w,
            height: 11.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList(ThemeData theme, List<Map<String, String>> faqItems) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(faqItems.length, (index) {
          final item = faqItems[index];

          return ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.3.h),
            childrenPadding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.colorScheme.onSurfaceVariant,
            title: Text(
              item['question']!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item['answer']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
