import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class DeleteEntryDialog extends ConsumerWidget {
  final String entryId;

  const DeleteEntryDialog({Key? key, required this.entryId}) : super(key: key);

  static void show(BuildContext context, String entryId) {
    showDialog(
      context: context,
      builder: (context) => DeleteEntryDialog(entryId: entryId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Delete Outfit'),
      content: const Text(
        'Are you sure you want to delete this outfit entry?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            ref.read(dailyLogEntriesProvider.notifier).deleteEntry(entryId);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Outfit deleted')),
            );
          },
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
