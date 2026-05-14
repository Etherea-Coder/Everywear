import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_localizations.dart';
import '../../widgets/custom_app_bar.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {

  final TextEditingController _email = TextEditingController();
  final TextEditingController _message = TextEditingController();

  String _categoryKey = "general";

  final List<String> _categoryKeys = [
    "general",
    "bug",
    "feature",
    "account"
  ];

  String _getCategoryLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case "general": return l10n.categoryGeneral;
      case "bug": return l10n.categoryBugReport;
      case "feature": return l10n.categoryFeatureRequest;
      case "account": return l10n.categoryAccountHelp;
      default: return key;
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.feedbackSent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.contactSupportTitle,
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              l10n.contactSupportHeroTitle,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 1.h),

            Text(
              l10n.contactSupportHeroSubtitle,
              style: theme.textTheme.bodyMedium,
            ),

            SizedBox(height: 3.h),

            Text(l10n.labelCategory, style: theme.textTheme.titleSmall),

            SizedBox(height: 1.h),

            DropdownButtonFormField<String>(
              value: _categoryKey,
              items: _categoryKeys
                  .map((k) => DropdownMenuItem(
                        value: k,
                        child: Text(_getCategoryLabel(k, l10n)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryKey = v!),
              decoration: const InputDecoration(),
            ),

            SizedBox(height: 2.h),

            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: l10n.labelEmailOptional,
              ),
            ),

            SizedBox(height: 2.h),

            TextField(
              controller: _message,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.labelMessageSupport,
              ),
            ),

            SizedBox(height: 3.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.sendMessage),
              ),
            ),

            SizedBox(height: 3.h),

            const Divider(),

            SizedBox(height: 2.h),

            Text(
              l10n.directSupportTitle,
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
