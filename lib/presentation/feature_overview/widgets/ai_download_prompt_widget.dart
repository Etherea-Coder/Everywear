import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/ai/model_download_service.dart';

/// AI Download Prompt Widget
/// Shown during onboarding to offer optional AI model download
class AIDownloadPromptWidget extends StatefulWidget {
  final VoidCallback onDownloadStarted;
  final VoidCallback onSkipped;

  const AIDownloadPromptWidget({
    Key? key,
    required this.onDownloadStarted,
    required this.onSkipped,
  }) : super(key: key);

  @override
  State<AIDownloadPromptWidget> createState() => _AIDownloadPromptWidgetState();
}

class _AIDownloadPromptWidgetState extends State<AIDownloadPromptWidget> {
  final ModelDownloadService _modelService = ModelDownloadService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _downloadComplete = false;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    widget.onDownloadStarted();

    final success = await _modelService.downloadModel(
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadComplete = success;
      });

      if (success) {
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ai_download_completed', true);

        // Show success message briefly
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          widget.onSkipped(); // Continue to next step
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _downloadComplete
                  ? Icons.check_circle_outline
                  : Icons.offline_bolt_outlined,
              size: 64.sp,
              color: _downloadComplete
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 4.h),

          // Title
          Text(
            _downloadComplete ? 'AI Ready!' : 'AI Photo Analysis',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),

          // Description
          Text(
            _downloadComplete
                ? 'Your AI model is ready to use. Enjoy instant photo analysis!'
                : 'Everywear can analyze photos of your clothes automatically.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),

          // Feature box
          if (!_downloadComplete)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    theme,
                    'Download Size:',
                    '~400MB',
                    FontWeight.bold,
                  ),
                  SizedBox(height: 1.h),
                  _buildFeatureRow(
                    theme,
                    'Works Offline:',
                    null,
                    FontWeight.normal,
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                  SizedBox(height: 1.h),
                  _buildFeatureRow(
                    theme,
                    'Private (on-device):',
                    null,
                    FontWeight.normal,
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                ],
              ),
            ),

          SizedBox(height: 4.h),

          // Download progress
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '${(_downloadProgress * 100).toInt()}% downloaded',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Action buttons
          if (!_isDownloading && !_downloadComplete) ...[
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Download AI Now',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: widget.onSkipped,
              child: Text(
                "I'll Add Items Manually",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You can download this later in Settings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    ThemeData theme,
    String label,
    String? value,
    FontWeight valueWeight, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        if (value != null)
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: valueWeight,
              color: theme.colorScheme.onSurface,
            ),
          ),
        if (icon != null)
          Icon(
            icon,
            color: iconColor ?? theme.colorScheme.primary,
            size: 20.sp,
          ),
      ],
    );
  }
}