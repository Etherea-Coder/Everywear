import 'package:flutter/material.dart';

class EditEntryDialog extends StatelessWidget {
  const EditEntryDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditEntryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Outfit'),
      content: const Text(
        'Edit functionality will allow you to modify outfit details.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
