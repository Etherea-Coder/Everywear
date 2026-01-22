import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class QuickLogButtonWidget extends StatelessWidget {
  final VoidCallback onQuickLog;
  final VoidCallback onFullLog;

  const QuickLogButtonWidget({
    Key? key,
    required this.onQuickLog,
    required this.onFullLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'quickLog',
          onPressed: onQuickLog,
          backgroundColor: AppTheme.primaryLight,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}