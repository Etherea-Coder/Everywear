import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// A soft, tinted container that groups related content together.
/// Creates a "quiet island" effect for premium feel.
class TintedSectionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;

  const TintedSectionContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: padding ?? EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}
