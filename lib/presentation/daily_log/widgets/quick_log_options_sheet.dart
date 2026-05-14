import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class QuickLogOptionsSheet extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onLogPrevious;
  final VoidCallback onRepeatOutfit;

  const QuickLogOptionsSheet({
    Key? key,
    required this.onTakePhoto,
    required this.onLogPrevious,
    required this.onRepeatOutfit,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required VoidCallback onTakePhoto,
    required VoidCallback onLogPrevious,
    required VoidCallback onRepeatOutfit,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => QuickLogOptionsSheet(
        onTakePhoto: onTakePhoto,
        onLogPrevious: onLogPrevious,
        onRepeatOutfit: onRepeatOutfit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          Text(
            'Quick Log Options',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          _buildQuickOption(
            context: context,
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Capture your outfit now',
            onTap: () {
              Navigator.pop(context);
              onTakePhoto();
            },
          ),
          _buildQuickOption(
            context: context,
            icon: Icons.history,
            title: 'Log Previous Outfit',
            subtitle: 'Add outfit from earlier today',
            onTap: () {
              Navigator.pop(context);
              onLogPrevious();
            },
          ),
          _buildQuickOption(
            context: context,
            icon: Icons.repeat,
            title: 'Repeat Outfit',
            subtitle: 'Log a previously worn outfit',
            onTap: () {
              Navigator.pop(context);
              onRepeatOutfit();
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildQuickOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
      ),
      onTap: onTap,
    );
  }
}
