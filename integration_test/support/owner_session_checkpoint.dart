import 'package:flutter/material.dart';

Future<bool> showOwnerSessionCheckpoint(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          key: const ValueKey('confirm_normal_session_checkpoint'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('I checked — continue'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
