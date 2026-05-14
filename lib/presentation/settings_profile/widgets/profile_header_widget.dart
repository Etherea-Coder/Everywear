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
    final isFree = membershipTier.toLowerCase() == 'free';
    final displayTier = _getDisplayTier(membershipTier);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
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
                    color: isFree
                        ? theme.colorScheme.outline.withValues(alpha: 0.35)
                        : _getMembershipAccentColor(membershipTier, theme),
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
          SizedBox(height: 2.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            email,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.2.w, vertical: 0.7.h),
            decoration: BoxDecoration(
              color: _getMembershipBackgroundColor(membershipTier, theme),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: _getMembershipBorderColor(membershipTier, theme),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMembershipIcon(membershipTier),
                  size: 14.sp,
                  color: _getMembershipTextColor(membershipTier, theme),
                ),
                SizedBox(width: 1.2.w),
                Text(
                  displayTier,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _getMembershipTextColor(membershipTier, theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMembershipAccentColor(String tier, ThemeData theme) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const Color(0xFFD4AF37);
      case 'pro':
        return theme.colorScheme.primary;
      case 'free':
      default:
        return theme.colorScheme.outline.withValues(alpha: 0.35);
    }
  }

  Color _getMembershipBackgroundColor(String tier, ThemeData theme) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const Color(0xFFD4AF37).withValues(alpha: 0.14);
      case 'pro':
        return theme.colorScheme.primary.withValues(alpha: 0.12);
      case 'free':
      default:
        return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    }
  }

  Color _getMembershipBorderColor(String tier, ThemeData theme) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const Color(0xFFD4AF37).withValues(alpha: 0.35);
      case 'pro':
        return theme.colorScheme.primary.withValues(alpha: 0.25);
      case 'free':
      default:
        return theme.colorScheme.outline.withValues(alpha: 0.18);
    }
  }

  Color _getMembershipTextColor(String tier, ThemeData theme) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return const Color(0xFF8B6A00);
      case 'pro':
        return theme.colorScheme.primary;
      case 'free':
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getMembershipIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return Icons.star_rounded;
      case 'pro':
        return Icons.workspace_premium_rounded;
      case 'free':
      default:
        return Icons.person_outline_rounded;
    }
  }

  /// Maps stored membership tier to display name
  String _getDisplayTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return 'Essential';
      case 'premium':
        return 'Signature';
      case 'pro':
        return 'Signature';
      default:
        return tier; // Return original if unknown
    }
  }
}