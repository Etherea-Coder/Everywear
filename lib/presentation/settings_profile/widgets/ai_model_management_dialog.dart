import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../services/ai/vision_engine_service.dart';
import '../../../services/ai/model_download_service.dart';

/// AI Model Management Dialog
/// Allows users to download and manage the local AI model
/// Enhanced for three-tier AI system
class AIModelManagementDialog extends StatefulWidget {
  const AIModelManagementDialog({Key? key}) : super(key: key);

  @override
  State<AIModelManagementDialog> createState() =>
      _AIModelManagementDialogState();
}

class _AIModelManagementDialogState extends State<AIModelManagementDialog> {
  final VisionEngineService _visionEngine = VisionEngineService();
  final ModelDownloadService _modelService = ModelDownloadService();
  bool _isModelDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isChecking = true;
  double _modelSizeMB = 0.0;
  String _selectedTier = 'cloud'; // 'cloud' or 'on-device'

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final isDownloaded = await _visionEngine.isModelDownloaded();
      final sizeMB = await _modelService.getModelSize();
      setState(() {
        _isModelDownloaded = isDownloaded;
        _modelSizeMB = sizeMB;
        _selectedTier = isDownloaded ? 'on-device' : 'cloud';
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _visionEngine.downloadModel(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _isModelDownloaded = true;
        _selectedTier = 'on-device';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI model downloaded successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Refresh size
      final sizeMB = await _modelService.getModelSize();
      setState(() => _modelSizeMB = sizeMB);
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to download AI model'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI Model?'),
        content: const Text(
          'This will free up ~400MB of storage. You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _modelService.deleteModel();
      if (success && mounted) {
        setState(() {
          _isModelDownloaded = false;
          _modelSizeMB = 0.0;
          _selectedTier = 'cloud';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI model deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                'Choose how Everywear analyzes your clothing photos:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              SizedBox(height: 3.h),

              // Tier selection
              _buildTierOption(
                theme,
                'cloud',
                'Cloud AI (Free)',
                'Requires internet • Fast • No storage needed',
                Icons.cloud_outlined,
              ),
              SizedBox(height: 2.h),
              _buildTierOption(
                theme,
                'on-device',
                'On-Device AI',
                'Works offline • More private • Requires 400MB',
                Icons.offline_bolt_outlined,
              ),

              SizedBox(height: 3.h),

              // Model Status
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: _isModelDownloaded
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: _isModelDownloaded
                              ? 'check_circle'
                              : 'cloud_download',
                          color: _isModelDownloaded
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isChecking
                                    ? 'Checking status...'
                                    : _isModelDownloaded
                                        ? 'AI Model Downloaded'
                                        : 'AI Model Not Downloaded',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _isModelDownloaded
                                    ? '${_modelSizeMB.toStringAsFixed(0)}MB used'
                                    : 'Download required (~400MB)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Download Progress
                    if (_isDownloading) ...[
                      SizedBox(height: 2.h),
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${(_downloadProgress * 100).toInt()}% downloaded',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Action buttons
              if (!_isDownloading) ...[
                if (!_isModelDownloaded)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _downloadModel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Download AI Model'),
                    ),
                  ),
                if (_isModelDownloaded)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _deleteModel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete AI Model (Free Space)'),
                    ),
                  ),
              ],

              SizedBox(height: 2.h),

              // Note
              Text(
                'You can always use manual entry regardless of AI settings.',
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

  Widget _buildTierOption(
    ThemeData theme,
    String tier,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedTier == tier;
    final isAvailable = tier == 'cloud' || _isModelDownloaded;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() => _selectedTier = tier);
            }
          : null,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 28.sp,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
          ],
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