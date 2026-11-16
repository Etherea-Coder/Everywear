import 'package:flutter/material.dart';

class StagingBuildBanner extends StatelessWidget {
  const StagingBuildBanner({
    required this.enabled,
    required this.child,
    this.testBuild = false,
    super.key,
  });

  final bool enabled;
  final Widget child;
  final bool testBuild;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    if (testBuild) {
      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 44,
                  color: const Color(0xFFD84315),
                  alignment: Alignment.center,
                  child: const Text(
                    'AUTOMATED TEST APP  •  STAGING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

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
