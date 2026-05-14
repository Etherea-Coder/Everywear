import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmptyDailyLogWidget extends StatelessWidget {
  const EmptyDailyLogWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 2.h),
          Text(
            'No outfits logged for this day',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tap the + button to log your outfit',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
