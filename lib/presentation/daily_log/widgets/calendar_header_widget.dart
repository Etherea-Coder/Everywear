import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CalendarHeaderWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<String, List<Map<String, dynamic>>> outfitEntries;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const CalendarHeaderWidget({
    Key? key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.outfitEntries,
    required this.onDateSelected,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final newMonth = DateTime(
                    focusedMonth.year,
                    focusedMonth.month - 1,
                  );
                  onMonthChanged(newMonth);
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(focusedMonth),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final newMonth = DateTime(
                    focusedMonth.year,
                    focusedMonth.month + 1,
                  );
                  onMonthChanged(newMonth);
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Week Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => SizedBox(
                    width: 12.w,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 1.h),
          // Calendar Grid
          _buildCalendarGrid(context),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    // Add empty spaces for days before month starts
    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(SizedBox(width: 12.w, height: 12.w));
    }

    // Add day widgets
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final hasEntries =
          outfitEntries.containsKey(dateKey) &&
          outfitEntries[dateKey]!.isNotEmpty;
      final isSelected =
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      dayWidgets.add(
        GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            width: 12.w,
            height: 12.w,
            margin: EdgeInsets.all(0.5.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryLight
                  : isToday
                  ? AppTheme.primaryLight.withAlpha(26)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
              border: hasEntries
                  ? Border.all(color: AppTheme.primaryLight, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppTheme.primaryLight
                          : Colors.black87,
                    ),
                  ),
                ),
                if (hasEntries && !isSelected)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(children: dayWidgets);
  }
}