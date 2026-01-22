import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_image_widget.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;
  final String membershipTier;
  final VoidCallback onEditProfile;

  const ProfileHeaderWidget({
    Key? key,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.membershipTier,
    required this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 25.w,
                height: 25.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: avatarUrl,
                    semanticLabel: 'Profile picture of $name',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditProfile,
                  child: Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.edit, size: 16.sp, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            email,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getMembershipColor(membershipTier, theme),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMembershipIcon(membershipTier),
                  size: 14.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 1.w),
                Text(
                  membershipTier,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMembershipColor(String tier, ThemeData theme) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const Color(0xFFD4AF37);
      case 'pro':
        return theme.colorScheme.primary;
      case 'free':
      default:
        return theme.colorScheme.secondary;
    }
  }

  IconData _getMembershipIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return Icons.star;
      case 'pro':
        return Icons.workspace_premium;
      case 'free':
      default:
        return Icons.person;
    }
  }
}