import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ProfileService _profileService = ProfileService();

  bool _isSaving = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final error = await _profileService.changePassword(
        newPassword: _newPasswordController.text.trim(),
      );
      if (!mounted) return;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update password: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Change Password'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: theme.colorScheme.primary, size: 20),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Choose a strong password with at least 8 characters.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 8) return 'At least 8 characters';
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim() != _newPasswordController.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
