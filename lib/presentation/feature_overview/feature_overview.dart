import 'package:flutter/material.dart';
import 'package:everywear/core/utils/app_localizations.dart';
import 'package:sizer/sizer.dart';


/// Feature Overview Screen - Second onboarding screen
/// Showcases core features of Everywear before personalization setup
class FeatureOverview extends StatefulWidget {
  const FeatureOverview({Key? key}) : super(key: key);

  @override
  State<FeatureOverview> createState() => _FeatureOverviewState();
}

class _FeatureOverviewState extends State<FeatureOverview> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> _getFeatures(AppLocalizations localizations) => [
    {
      'icon': Icons.camera_alt_outlined,
      'title': localizations.featureCaptureTitle,
      'description': localizations.featureCaptureDesc,
      'color': const Color(0xFF2D5A27),
    },
    {
      'icon': Icons.checkroom_outlined,
      'title': localizations.featureWardrobeTitle,
      'description': localizations.featureWardrobeDesc,
      'color': const Color(0xFF8B4513),
    },
    {
      'icon': Icons.auto_awesome_outlined,
      'title': localizations.featureSuggestionsTitle,
      'description': localizations.featureSuggestionsDesc,
      'color': const Color(0xFF4A7C59),
    },
    {
      'icon': Icons.insights_outlined,
      'title': localizations.featureInsightsTitle,
      'description': localizations.featureInsightsDesc,
      'color': const Color(0xFFB8860B),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _navigateToPersonalization() {
    Navigator.of(context).pushReplacementNamed('/personalization-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final features = _getFeatures(localizations);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _navigateToPersonalization,
                  child: Text(
                    localizations.skip,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Page view with features
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: features.length,
                itemBuilder: (context, index) {
                  return _buildFeaturePage(context, features[index]);
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  features.length,
                  (index) => _buildPageIndicator(context, index),
                ),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        ),
                        child: Text(
                          localizations.back,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) SizedBox(width: 3.w),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < features.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToPersonalization();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      ),
                      child: Text(
                        _currentPage < features.length - 1
                            ? localizations.next
                            : localizations.continueText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePage(BuildContext context, Map<String, dynamic> feature) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feature icon
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature['icon'] as IconData,
              size: 64.sp,
              color: feature['color'] as Color,
            ),
          ),
          SizedBox(height: 4.h),
          // Feature title
          Text(
            feature['title'] as String,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          // Feature description
          Text(
            feature['description'] as String,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      height: 1.h,
      width: isActive ? 6.w : 2.w,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
