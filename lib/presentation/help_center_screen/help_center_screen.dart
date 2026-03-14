import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'What is Everywear?',
      'answer':
          'Everywear is your personal wardrobe studio. It helps you organize your clothes, get daily outfit ideas, track your style habits, and make more thoughtful purchase decisions.',
    },
    {
      'question': 'How should I start using the app?',
      'answer':
          'Start by adding a few key wardrobe items, then log outfits as you wear them. The more you use the app, the more personal and accurate your suggestions, insights, and coaching become.',
    },
    {
      'question': 'What does the Today page do?',
      'answer':
          'The Today page is your daily styling space. It gives you an outfit idea based on your wardrobe, your selected mood, your plans, and contextual details like weather or upcoming events.',
    },
    {
      'question': 'What is the Style page for?',
      'answer':
          'The Style page is your coaching space. It is designed for reflection, challenges, quizzes, style growth, and more personal guidance beyond the daily suggestion.',
    },
    {
      'question': 'What are Style Insights?',
      'answer':
          'Style Insights show patterns in how you use your wardrobe — like your most worn categories, outfit history, wardrobe utilization, and value over time. They help you understand your style more clearly.',
    },
    {
      'question': 'What is the difference between Essential and Signature?',
      'answer':
          'Essential gives you access to the core experience of Everywear. Signature unlocks more suggestions, more coaching, more outfit options, and a smoother premium experience with fewer limitations.',
    },
    {
      'question': 'Will the app delete my wardrobe if I cancel Signature?',
      'answer':
          'No. Your wardrobe data stays with your account. If you return to Essential, you keep your saved data, but some premium features and extra usage limits may no longer be available.',
    },
    {
      'question': 'How do purchases and wishlist tracking work?',
      'answer':
          'The Purchases page helps you log what enters your wardrobe, monitor category spending, track cost-per-wear, and save items to a wishlist before buying them.',
    },
    {
      'question': 'Does Everywear sell my personal data?',
      'answer':
          'No. Your wardrobe and account data are used to power your experience inside the app. Analytics settings let you control whether anonymous usage data helps improve the app.',
    },
    {
      'question': 'How can I get better suggestions?',
      'answer':
          'Add more wardrobe items, complete your style quiz, log outfits regularly, and use the occasion and vibe options. This gives the app more context to produce suggestions that feel more personal.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Help Center',
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(theme),
            SizedBox(height: 1.5.h),
            _buildStudioIntro(theme),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: 'Our Philosophy',
              icon: Icons.spa_outlined,
              child: _buildInfoCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Everywear is designed as a calm personal wardrobe space.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'The goal is not to pressure you to buy more or dress in a certain way. The goal is to help you see your wardrobe more clearly, use it more intentionally, and build a style that feels like your own.',
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
              title: 'How Everywear Works',
              icon: Icons.auto_awesome_outlined,
              child: Column(
                children: [
                  _buildStepCard(
                    theme,
                    number: '1',
                    title: 'Add your wardrobe',
                    description:
                        'Start with a few pieces you wear often. You do not need to add everything at once.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildStepCard(
                    theme,
                    number: '2',
                    title: 'Log your outfits',
                    description:
                        'Track what you actually wear. This helps the app understand your habits and improve your suggestions.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildStepCard(
                    theme,
                    number: '3',
                    title: 'Explore your daily suggestions',
                    description:
                        'Use the Today page to get outfit ideas based on your mood, plans, and wardrobe context.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildStepCard(
                    theme,
                    number: '4',
                    title: 'Grow your style with coaching',
                    description:
                        'Use the Style page to discover challenges, answer quizzes, and get more thoughtful guidance over time.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.5.h),
            _buildProTipCard(theme),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: 'What each page does',
              icon: Icons.dashboard_outlined,
              child: Column(
                children: [
                  _buildFeatureCard(
                    theme,
                    icon: Icons.today_outlined,
                    title: 'Today',
                    description:
                        'Your daily landing space for outfit ideas, quick logs, and morning guidance.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.checkroom_outlined,
                    title: 'Wardrobe',
                    description:
                        'Your personal collection of clothes, organized and ready to style.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.auto_awesome,
                    title: 'Style',
                    description:
                        'Your coaching area for quizzes, challenges, events, and personal growth.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Purchases',
                    description:
                        'Track wardrobe spending, wishlist items, and the long-term value of what you buy.',
                  ),
                  SizedBox(height: 1.2.h),
                  _buildFeatureCard(
                    theme,
                    icon: Icons.person_outline,
                    title: 'Profile',
                    description:
                        'See your insights, achievements, progress, membership, and settings.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: 'Membership',
              icon: Icons.workspace_premium_outlined,
              child: _buildInfoCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Essential',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.6.h),
                    Text(
                      'A refined core experience with wardrobe management, daily use, and selected AI guidance.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Signature',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.6.h),
                    Text(
                      'A deeper experience with more suggestions, more coaching, more outfit possibilities, and a more seamless premium journey.',
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
              title: 'Frequently Asked Questions',
              icon: Icons.help_outline,
              child: _buildFaqList(theme),
            ),
            SizedBox(height: 2.h),
            _buildSection(
              theme,
              title: 'Need more help?',
              icon: Icons.mail_outline,
              child: _buildInfoCard(
                theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'If something does not work as expected, or if you want to share feedback, please use the feedback option in Settings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    Text(
                      'Everywear is designed to evolve thoughtfully, and your feedback helps shape that process.',
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

  Widget _buildHeroCard(ThemeData theme) {
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
                  'Welcome to the Everywear Help Center',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'A calm guide to how the app works, what each space is for, and how to get the most out of your wardrobe journey.',
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

  Widget _buildStudioIntro(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Everywear is designed as a calm studio for your wardrobe. '
          'This space helps you understand how the app works, how to grow your style, '
          'and how to get the most from your clothes.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildProTipCard(ThemeData theme) {
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
                'Tip: The more outfits you log, the more personal your daily suggestions and insights become.',
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

  Widget _buildFaqList(ThemeData theme) {
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
        children: List.generate(_faqItems.length, (index) {
          final item = _faqItems[index];
          final isLast = index == _faqItems.length - 1;

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
