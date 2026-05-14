import 'package:flutter/material.dart';

class RepeatOutfitDialog extends StatelessWidget {
  const RepeatOutfitDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RepeatOutfitDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Repeat Outfit'),
      content: const Text(
        'This feature will show your previous outfits to quickly log again.',
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
