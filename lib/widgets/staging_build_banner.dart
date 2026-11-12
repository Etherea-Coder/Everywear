import 'package:flutter/material.dart';

class StagingBuildBanner extends StatelessWidget {
  const StagingBuildBanner({
    required this.enabled,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Banner(
      message: 'STAGING',
      location: BannerLocation.topEnd,
      color: Colors.deepOrange,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
      child: child,
    );
  }
}
