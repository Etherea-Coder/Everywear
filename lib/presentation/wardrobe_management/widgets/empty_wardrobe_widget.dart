import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmptyWardrobeWidget extends StatelessWidget {
  final bool hasSearchQuery;
  final VoidCallback onAddItem;

  const EmptyWardrobeWidget({
    Key? key,
    required this.hasSearchQuery,
    required this.onAddItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (hasSearchQuery) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 2.h),
            Text(
              'No items found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hanger illustration
            _buildHangerIllustration(theme),
            SizedBox(height: 3.h),

            // Title
            Text(
              'Your wardrobe starts here',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),

            // Subtitle
            Text(
              'Add your clothes to unlock outfit suggestions\nand styling insights.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Quick add label
            Text(
              'Start with something simple',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 1.5.h),

            // Quick add buttons
            _buildQuickAddButton(
              context,
              theme,
              emoji: '👕',
              label: 'Add a top',
              category: 'Tops',
            ),
            SizedBox(height: 1.h),
            _buildQuickAddButton(
              context,
              theme,
              emoji: '👖',
              label: 'Add pants',
              category: 'Bottoms',
            ),
            SizedBox(height: 1.h),
            _buildQuickAddButton(
              context,
              theme,
              emoji: '👟',
              label: 'Add shoes',
              category: 'Shoes',
            ),

            SizedBox(height: 2.5.h),

            // Divider with OR
            Row(
              children: [
                Expanded(
                  child: Divider(color: theme.dividerColor),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Text(
                    'OR',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: theme.dividerColor),
                ),
              ],
            ),

            SizedBox(height: 2.5.h),

            // Full add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: const Text('Add first item'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHangerIllustration(ThemeData theme) {
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: CustomPaint(
        painter: _HangerPainter(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildQuickAddButton(
    BuildContext context,
    ThemeData theme, {
    required String emoji,
    required String label,
    required String category,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/add-clothing-item',
            arguments: {'preselectedCategory': category},
          );
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.4.h, horizontal: 4.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            SizedBox(width: 3.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HangerPainter extends CustomPainter {
  final Color color;

  _HangerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Hook at top
    final hookPath = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..cubicTo(
        w * 0.5, h * 0.02,
        w * 0.68, h * 0.02,
        w * 0.68, h * 0.13,
      );
    canvas.drawPath(hookPath, paint);

    // Neck of hanger (small vertical line)
    canvas.drawLine(
      Offset(w * 0.5, h * 0.18),
      Offset(w * 0.5, h * 0.30),
      paint,
    );

    // Main hanger triangle body
    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.30)
      ..lineTo(w * 0.05, h * 0.72)
      ..lineTo(w * 0.95, h * 0.72)
      ..close();

    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, paint);

    // Bottom bar
    canvas.drawLine(
      Offset(w * 0.05, h * 0.72),
      Offset(w * 0.95, h * 0.72),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HangerPainter oldDelegate) => oldDelegate.color != color;
}