import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import './widgets/lifestyle_context_step.dart';
import './widgets/style_preference_step.dart';
import './widgets/sustainability_goals_step.dart';
import './widgets/wardrobe_upload_step.dart';

/// Personalization Setup Screen - Final onboarding screen
/// Multi-step wizard collecting user preferences through progressive disclosure
class PersonalizationSetup extends StatefulWidget {
  const PersonalizationSetup({Key? key}) : super(key: key);

  @override
  State<PersonalizationSetup> createState() => _PersonalizationSetupState();
}

class _PersonalizationSetupState extends State<PersonalizationSetup> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // User preference data
  List<String> _selectedStyles = [];
  String? _workEnvironment;
  String? _socialFrequency;
  String? _climate;
  double _purchaseFrequency = 3.0;
  double _budgetConsciousness = 3.0;
  double _environmentalImpact = 3.0;
  List<String> _wardrobePhotos = [];

  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStylesChanged(List<String> styles) {
    setState(() => _selectedStyles = styles);
  }

  void _onLifestyleChanged({String? work, String? social, String? climate}) {
    setState(() {
      if (work != null) _workEnvironment = work;
      if (social != null) _socialFrequency = social;
      if (climate != null) _climate = climate;
    });
  }

  void _onSustainabilityChanged({
    double? purchase,
    double? budget,
    double? environmental,
  }) {
    setState(() {
      if (purchase != null) _purchaseFrequency = purchase;
      if (budget != null) _budgetConsciousness = budget;
      if (environmental != null) _environmentalImpact = environmental;
    });
  }

  void _onPhotosChanged(List<String> photos) {
    setState(() => _wardrobePhotos = photos);
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _selectedStyles.isNotEmpty;
      case 1:
        return _workEnvironment != null &&
            _socialFrequency != null &&
            _climate != null;
      case 2:
        return true; // Sustainability step is always valid
      case 3:
        return true; // Wardrobe upload is optional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isCompleting = true);

    try {
      // Save user preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedStyles', _selectedStyles);
      await prefs.setString('workEnvironment', _workEnvironment ?? '');
      await prefs.setString('socialFrequency', _socialFrequency ?? '');
      await prefs.setString('climate', _climate ?? '');
      await prefs.setDouble('purchaseFrequency', _purchaseFrequency);
      await prefs.setDouble('budgetConsciousness', _budgetConsciousness);
      await prefs.setDouble('environmentalImpact', _environmentalImpact);
      await prefs.setBool('hasSeenOnboarding', true);

      // Simulate generating insights
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Navigate to main app
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(AppRoutes.outfitCaptureFlow);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to save preferences. Please try again.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Personalize Your Experience',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(context),
          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StylePreferenceStep(
                  selectedStyles: _selectedStyles,
                  onStylesChanged: _onStylesChanged,
                ),
                LifestyleContextStep(
                  workEnvironment: _workEnvironment,
                  socialFrequency: _socialFrequency,
                  climate: _climate,
                  onLifestyleChanged: _onLifestyleChanged,
                ),
                SustainabilityGoalsStep(
                  purchaseFrequency: _purchaseFrequency,
                  budgetConsciousness: _budgetConsciousness,
                  environmentalImpact: _environmentalImpact,
                  onSustainabilityChanged: _onSustainabilityChanged,
                ),
                WardrobeUploadStep(
                  photos: _wardrobePhotos,
                  onPhotosChanged: _onPhotosChanged,
                ),
              ],
            ),
          ),
          // Navigation button
          _buildNavigationButton(context),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              _totalSteps,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 2.w : 0,
                  ),
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withAlpha(51),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context) {
    final theme = Theme.of(context);
    final canProceed = _canProceedFromStep(_currentStep);
    final isLastStep = _currentStep == _totalSteps - 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: SizedBox(
        width: double.infinity,
        height: 6.h,
        child: ElevatedButton(
          onPressed: canProceed && !_isCompleting ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.primary.withAlpha(77),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: _isCompleting
              ? SizedBox(
                  height: 2.5.h,
                  width: 2.5.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  isLastStep ? 'Complete Setup' : 'Continue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
