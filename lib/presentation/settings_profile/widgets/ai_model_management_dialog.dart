import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../services/ai/vision_engine_service.dart';

/// AI Model Management Dialog
/// Shows information about the AI system (cloud-based)
class AIModelManagementDialog extends StatefulWidget {
  const AIModelManagementDialog({Key? key}) : super(key: key);

  @override
  State<AIModelManagementDialog> createState() =>
      _AIModelManagementDialogState();
}

class _AIModelManagementDialogState extends State<AIModelManagementDialog> {
  final VisionEngineService _visionEngine = VisionEngineService();
  String _currentTier = 'checking';

  @override
  void initState() {
    super.initState();
    _checkAITier();
  }

  Future<void> _checkAITier() async {
    final tier = await _visionEngine.getAITier();
    if (mounted) {
      setState(() => _currentTier = tier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'auto_awesome',
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'AI Features',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Description
              Text(
                'AI Photo Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Everywear uses cloud-based AI to analyze your clothing photos:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              SizedBox(height: 3.h),

              // Cloud AI Status
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: _currentTier == 'cloud' ? 'check_circle' : 'cloud',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cloud AI (Gemini)',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _currentTier == 'cloud'
                                    ? 'Connected and ready'
                                    : _currentTier == 'checking'
                                        ? 'Checking connection...'
                                        : 'Offline - manual entry available',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Features
              _buildFeatureItem(
                theme,
                'camera',
                'Smart Photo Analysis',
                'Automatically detect clothing category, color, and material',
              ),
              _buildFeatureItem(
                theme,
                'lightbulb',
                'Style Suggestions',
                'Get personalized outfit recommendations',
              ),
              _buildFeatureItem(
                theme,
                'eco',
                'Sustainability Insights',
                'Track cost-per-wear and wardrobe efficiency',
              ),

              SizedBox(height: 2.h),

              // Note
              Text(
                'Requires internet connection. Manual entry is always available as fallback.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    String iconName,
    String title,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
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
}