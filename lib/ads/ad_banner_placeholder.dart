import 'package:flutter/material.dart';

/// Banner ad placeholder - reserves 50px for future AdMob banner
///
/// This placeholder ensures your UI layout is ready for ads.
/// When you integrate AdMob, replace this widget with a real BannerAd.
///
/// Standard banner sizes:
/// - Banner: 320x50 (most common)
/// - Large Banner: 320x100
/// - Medium Rectangle: 300x250
class AdBannerPlaceholder extends StatelessWidget {
  /// Height of the banner (default: 50 for standard banner)
  final double height;

  /// Whether to show a visual placeholder during development
  final bool showDebugBackground;

  /// Optional background color for debug mode
  final Color? debugColor;

  const AdBannerPlaceholder({
    Key? key,
    this.height = 50,
    this.showDebugBackground = false,
    this.debugColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // During development, you can enable debug background to see the reserved space
    if (showDebugBackground) {
      return Container(
        height: height,
        width: double.infinity,
        color: debugColor ?? Colors.grey.withValues(alpha: 0.2),
        child: Center(
          child: Text(
            'Ad Banner Space (${height.toInt()}px)',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Production mode: transparent placeholder
    return SizedBox(
      height: height,
      width: double.infinity,
    );
  }
}
