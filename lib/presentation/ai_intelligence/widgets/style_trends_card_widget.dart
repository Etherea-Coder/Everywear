import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class StyleTrendsCardWidget extends StatefulWidget {
  final List<String> dominantColors;
  final List<int> colorPercentages;
  final List<Map<String, dynamic>> silhouetteEvolution;
  final List<String> emergingStyles;

  const StyleTrendsCardWidget({
    Key? key,
    required this.dominantColors,
    required this.colorPercentages,
    required this.silhouetteEvolution,
    required this.emergingStyles,
  }) : super(key: key);

  @override
  State<StyleTrendsCardWidget> createState() => _StyleTrendsCardWidgetState();
}

class _StyleTrendsCardWidgetState extends State<StyleTrendsCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          if (_isExpanded) ..._buildExpandedContent(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: Colors.purple,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Style Trends Analysis',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Color patterns & style evolution',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExpandedContent(ThemeData theme) {
    return [
      Divider(height: 1, color: theme.dividerColor),
      Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dominant Colors',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildColorChart(theme),
            SizedBox(height: 3.h),
            Text(
              'Emerging Style Directions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildEmergingStyles(theme),
          ],
        ),
      ),
    ];
  }

  Widget _buildColorChart(ThemeData theme) {
    final colorMap = {
      'Blue': Colors.blue,
      'Black': Colors.black,
      'White': Colors.grey.shade300,
      'Gray': Colors.grey,
      'Red': Colors.red,
      'Green': Colors.green,
    };

    return Column(
      children: List.generate(widget.dominantColors.length, (index) {
        final color = widget.dominantColors[index];
        final percentage = widget.colorPercentages[index];
        final colorValue = colorMap[color] ?? Colors.grey;

        return Padding(
          padding: EdgeInsets.only(bottom: 1.5.h),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorValue,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          color,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.dividerColor.withValues(
                        alpha: 0.3,
                      ),
                      color: colorValue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmergingStyles(ThemeData theme) {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: widget.emergingStyles.map((style) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, color: Colors.purple, size: 16),
              SizedBox(width: 1.w),
              Text(
                style,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
