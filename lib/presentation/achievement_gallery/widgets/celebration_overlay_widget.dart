import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

/// Celebration overlay widget with confetti animation for achievement unlocks
class CelebrationOverlayWidget extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback onComplete;

  const CelebrationOverlayWidget({
    Key? key,
    required this.controller,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CelebrationOverlayWidget> createState() =>
      _CelebrationOverlayWidgetState();
}

class _CelebrationOverlayWidgetState extends State<CelebrationOverlayWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.3 * widget.controller.value),
          child: Stack(
            children: [
              // Confetti particles
              ...List.generate(30, (index) {
                final random = math.Random(index);
                final startX = random.nextDouble() * 100.w;
                final endY = 100.h + 50;
                final rotation = random.nextDouble() * 2 * math.pi;
                final color = _getRandomColor(random);

                return Positioned(
                  left: startX,
                  top: -50 + (endY * widget.controller.value),
                  child: Transform.rotate(
                    angle: rotation * widget.controller.value,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: random.nextBool()
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                      ),
                    ),
                  ),
                );
              }),

              // Center message
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: widget.controller,
                      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Achievement Unlocked!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Keep up the great work!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFF45B7D1), // Blue
      const Color(0xFFFFA07A), // Orange
      const Color(0xFF98D8C8), // Mint
    ];
    return colors[random.nextInt(colors.length)];
  }
}
