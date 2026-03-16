import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_image_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSaving = false;
  String _avatarUrl = '';
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameController.text =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          '';
      _emailController.text = user.email ?? '';
      _avatarUrl = user.userMetadata?['avatar_url'] ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Edit Profile',
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(theme),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'Profile photo',
                icon: Icons.camera_alt_outlined,
                child: _buildPhotoCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'Display name',
                icon: Icons.person_outline,
                child: _buildNameCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'Email',
                icon: Icons.mail_outline,
                child: _buildEmailCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'Note',
                icon: Icons.info_outline,
                child: _buildInfoCard(theme),
              ),
              SizedBox(height: 3.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.16),
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your personal profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Keep your profile simple, clear, and personal. Your email stays fixed, while your name and profile image can be updated here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _avatarUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: _avatarUrl,
                          fit: BoxFit.cover,
                          semanticLabel: 'Profile picture',
                        )
                      : Container(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.person,
                            size: 42,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isSaving ? null : _pickAndUploadPhoto,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.8.h),
          Text(
            'Tap the photo to update it',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.6.h),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _pickAndUploadPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Change Photo'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Your name',
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your name';
          }
          if (value.trim().length < 2) {
            return 'Please enter a valid name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _emailController.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 0.6.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Fixed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        'Your email address stays linked to your account sign-in. To keep things simple and reliable, only your display name and profile image are editable here.',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isSaving = true);

      // Debug: Check file exists
      final file = File(picked.path);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      // Debug: Log file info
      debugPrint('Picked file: ${picked.path}');
      debugPrint('File exists: ${await file.exists()}');

      final url = await _profileService.uploadProfilePhoto(picked.path);

      debugPrint('Upload returned URL: $url');

      if (url != null && mounted) {
        setState(() => _avatarUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not upload photo. Check debug console for details.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Pick/Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _nameController.text.trim(),
          },
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}