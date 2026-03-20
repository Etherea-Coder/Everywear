import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RecommendationsCardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;

  const RecommendationsCardWidget({Key? key, required this.recommendations})
    : super(key: key);

  @override
  State<RecommendationsCardWidget> createState() =>
      _RecommendationsCardWidgetState();
}

class _RecommendationsCardWidgetState extends State<RecommendationsCardWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          SizedBox(
            height: 28.h,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: widget.recommendations.length,
              itemBuilder: (context, index) {
                return _buildRecommendationCard(
                  widget.recommendations[index],
                  theme,
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
          _buildPageIndicator(theme),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> recommendation,
    ThemeData theme,
  ) {
    final type        = (recommendation['type']        as String?)  ?? 'style';
    final title       = (recommendation['title']       as String?)  ?? 'Recommendation';
    final description = (recommendation['description'] as String?)  ?? '';
    final confidence  = (recommendation['confidence']  as num?)?.toInt() ?? 70;
    final reasoning   = (recommendation['reasoning']   as String?)  ?? '';

    final colors = _getTypeColors(type);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors['background']!,
            colors['background']!.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colors['border']!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: colors['iconBg'],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: colors['icon'],
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(type),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors['text']!.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors['text'],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildConfidenceBadge(confidence, colors['icon']!, theme),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: colors['icon'], size: 16),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    reasoning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(int confidence, Color color, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 14),
          SizedBox(width: 1.w),
          Text(
            '$confidence%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.recommendations.length,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppTheme.primaryLight
                : theme.dividerColor,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getTypeColors(String type) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    return {
      'background': secondary.withValues(alpha: 0.05),
      'border': secondary.withValues(alpha: 0.14),
      'iconBg': secondary.withValues(alpha: 0.10),
      'icon': secondary,
      'text': onSurface,
    };
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'gap':
        return Icons.add_circle_outline;
      case 'seasonal':
        return Icons.wb_sunny_outlined;
      case 'style':
        return Icons.style_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'gap':
        return 'WARDROBE GAP';
      case 'seasonal':
        return 'SEASONAL ADDITION';
      case 'style':
        return 'STYLE EVOLUTION';
      default:
        return 'RECOMMENDATION';
    }
  }
}
