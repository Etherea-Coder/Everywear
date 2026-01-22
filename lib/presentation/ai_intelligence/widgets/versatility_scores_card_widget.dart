import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class VersatilityScoresCardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> versatilityScores;
  final List<Map<String, dynamic>> underutilizedItems;

  const VersatilityScoresCardWidget({
    Key? key,
    required this.versatilityScores,
    required this.underutilizedItems,
  }) : super(key: key);

  @override
  State<VersatilityScoresCardWidget> createState() =>
      _VersatilityScoresCardWidgetState();
}

class _VersatilityScoresCardWidgetState
    extends State<VersatilityScoresCardWidget> {
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(Icons.star_outline, color: Colors.blue, size: 24),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outfit Versatility Scores',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Item combination potential',
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
              'Most Versatile Items',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ...widget.versatilityScores.map((item) {
              return _buildVersatilityItem(item, theme);
            }),
            SizedBox(height: 3.h),
            Text(
              'Underutilized Items',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ...widget.underutilizedItems.map((item) {
              return _buildUnderutilizedItem(item, theme);
            }),
          ],
        ),
      ),
    ];
  }

  Widget _buildVersatilityItem(Map<String, dynamic> item, ThemeData theme) {
    final score = item['score'] as int;
    final combinations = item['combinations'] as int;
    final itemName = item['item'] as String;

    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.blue;
    } else {
      scoreColor = Colors.orange;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$combinations outfit combinations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              '$score',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderutilizedItem(Map<String, dynamic> item, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Last worn: ${item['lastWorn']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              '${item['suggestions']} tips',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
