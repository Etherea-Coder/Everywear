import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Welcome Philosophy Screen - First onboarding screen
/// Introduces users to Everywear's personal style learning system and philosophy
class WelcomePhilosophy extends StatefulWidget {
  const WelcomePhilosophy({Key? key}) : super(key: key);

  @override
  State<WelcomePhilosophy> createState() => _WelcomePhilosophyState();
}

class _WelcomePhilosophyState extends State<WelcomePhilosophy>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToFeatureOverview() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.featureOverview);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  SizedBox(height: 6.h),
                  // Logo and branding
                  CustomImageWidget(
                    imageUrl: 'assets/images/logo-1768224674386.png',
                    height: 12.h,
                    width: 12.h,
                    semanticLabel:
                        'Everywear logo with sustainable earth palette colors',
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Welcome to Everywear',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Your Personal Style Learning System',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5.h),
                  // Philosophy content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPhilosophyCard(
                            context,
                            icon: Icons.psychology_outlined,
                            title: 'Learn Your Style',
                            description:
                                'Everywear learns from every outfit you wear, understanding what makes you feel confident and comfortable.',
                          ),
                          SizedBox(height: 2.h),
                          _buildPhilosophyCard(
                            context,
                            icon: Icons.eco_outlined,
                            title: 'Sustainable Choices',
                            description:
                                'Make the most of what you own. Discover forgotten pieces and reduce unnecessary purchases.',
                          ),
                          SizedBox(height: 2.h),
                          _buildPhilosophyCard(
                            context,
                            icon: Icons.lightbulb_outline,
                            title: 'Smart Insights',
                            description:
                                'Get personalized recommendations based on weather, occasion, and your unique style preferences.',
                          ),
                          SizedBox(height: 2.h),
                          _buildPhilosophyCard(
                            context,
                            icon: Icons.trending_up_outlined,
                            title: 'Grow With You',
                            description:
                                'Your style evolves, and so does Everywear. The more you use it, the better it understands you.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _navigateToFeatureOverview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhilosophyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
