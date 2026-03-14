import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {

  final TextEditingController _email = TextEditingController();
  final TextEditingController _message = TextEditingController();

  String _category = "General";

  final List<String> _categories = [
    "General",
    "Bug report",
    "Feature request",
    "Account help"
  ];

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback sent. Thank you!")),
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: "Contact & Support"),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "We’d love to hear from you",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 1.h),

            Text(
              "Questions, feedback, or ideas help make Everywear better.",
              style: theme.textTheme.bodyMedium,
            ),

            SizedBox(height: 3.h),

            Text("Category", style: theme.textTheme.titleSmall),

            SizedBox(height: 1.h),

            DropdownButtonFormField<String>(
              value: _category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(),
            ),

            SizedBox(height: 2.h),

            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: "Email (optional)",
              ),
            ),

            SizedBox(height: 2.h),

            TextField(
              controller: _message,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Message",
              ),
            ),

            SizedBox(height: 3.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text("Send message"),
              ),
            ),

            SizedBox(height: 3.h),

            Divider(),

            SizedBox(height: 2.h),

            Text(
              "Direct support",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 1.h),

            Text(
              "support@everywear.studio",
              style: theme.textTheme.bodyMedium,
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
