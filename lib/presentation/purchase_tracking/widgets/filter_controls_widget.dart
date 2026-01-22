import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';


/// Filter controls widget for purchase tracking
class FilterControlsWidget extends StatelessWidget {
  final String selectedFilter;
  final String selectedBrand;
  final DateTimeRange? dateRange;
  final List<String> availableBrands;
  final Function(String) onFilterChanged;
  final Function(String) onBrandChanged;
  final Function(DateTimeRange?) onDateRangeChanged;

  const FilterControlsWidget({
    Key? key,
    required this.selectedFilter,
    required this.selectedBrand,
    required this.dateRange,
    required this.availableBrands,
    required this.onFilterChanged,
    required this.onBrandChanged,
    required this.onDateRangeChanged,
  }) : super(key: key);

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // Brand filter
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBrand,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: availableBrands.map((brand) {
                    return DropdownMenuItem(
                      value: brand,
                      child: Text(
                        brand,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onBrandChanged(value);
                  },
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Date range filter
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dateRange != null
                            ? '${dateFormat.format(dateRange!.start)} - ${dateFormat.format(dateRange!.end)}'
                            : 'Date Range',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dateRange != null)
                      GestureDetector(
                        onTap: () => onDateRangeChanged(null),
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
