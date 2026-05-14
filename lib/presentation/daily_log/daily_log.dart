import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/providers.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/calendar_header_widget.dart';
import './widgets/outfit_entry_card_widget.dart';
import './widgets/quick_log_button_widget.dart';
import './widgets/stats_summary_widget.dart';
import './widgets/empty_daily_log_widget.dart';
import './widgets/quick_log_options_sheet.dart';
import './widgets/monthly_insights_dialog.dart';
import './widgets/repeat_outfit_dialog.dart';
import './widgets/edit_entry_dialog.dart';
import './widgets/delete_entry_dialog.dart';

class DailyLog extends ConsumerStatefulWidget {
  const DailyLog({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyLog> createState() => _DailyLogState();
}

class _DailyLogState extends ConsumerState<DailyLog> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(dailyLogSelectedDateProvider);
    final focusedMonth = ref.watch(dailyLogFocusedMonthProvider);
    final viewMode = ref.watch(dailyLogViewModeProvider);
    final entriesAsync = ref.watch(dailyLogEntriesProvider);
    final statsAsync = ref.watch(dailyLogMonthlyStatsProvider);

    final selectedDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    final Map<String, List<Map<String, dynamic>>> outfitEntriesByDate = {};
    entriesAsync.whenData((entries) {
      for (final entry in entries) {
        final dateKey = entry['worn_date'] != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['worn_date']))
            : selectedDateKey;
        outfitEntriesByDate.putIfAbsent(dateKey, () => []).add(entry);
      }
    });

    final todayEntries = outfitEntriesByDate[selectedDateKey] ?? [];

    final stats = statsAsync.whenData((data) => data).valueOrNull ??
        {'total_outfits': 0, 'unique_items': 0, 'favorite_occasion': 'None', 'avg_rating': 0.0};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Daily Log',
        actions: [
          IconButton(
            icon: Icon(
              viewMode == 'calendar' ? Icons.list : Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              ref.read(dailyLogViewModeProvider.notifier).state =
                  viewMode == 'calendar' ? 'list' : 'calendar';
            },
          ),
          IconButton(
            icon: Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _showInsights(stats),
          ),
        ],
      ),
      body: Column(
        children: [
          CalendarHeaderWidget(
            focusedMonth: focusedMonth,
            selectedDate: selectedDate,
            outfitEntries: outfitEntriesByDate,
            onDateSelected: (date) {
              ref.read(dailyLogSelectedDateProvider.notifier).state = date;
            },
            onMonthChanged: (month) {
              ref.read(dailyLogFocusedMonthProvider.notifier).state = month;
            },
          ),
          StatsSummaryWidget(
            totalOutfits: stats['total_outfits'] as int,
            uniqueItems: stats['unique_items'] as int,
            favoriteOccasion: stats['favorite_occasion'] as String,
          ),
          Expanded(
            child: todayEntries.isEmpty
                ? const EmptyDailyLogWidget()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: todayEntries.length,
                    itemBuilder: (context, index) {
                      return OutfitEntryCardWidget(
                        entry: todayEntries[index],
                        onEdit: () => EditEntryDialog.show(context),
                        onDelete: () => DeleteEntryDialog.show(
                          context,
                          todayEntries[index]['id']?.toString() ?? '',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: QuickLogButtonWidget(
        onQuickLog: _showQuickLogOptions,
        onFullLog: _navigateToFullLog,
      ),
    );
  }

  void _showQuickLogOptions() {
    QuickLogOptionsSheet.show(
      context,
      onTakePhoto: () {
        Navigator.pushNamed(context, AppRoutes.outfitCaptureFlow);
      },
      onLogPrevious: _navigateToFullLog,
      onRepeatOutfit: () => RepeatOutfitDialog.show(context),
    );
  }

  void _navigateToFullLog() {
    Navigator.pushNamed(context, AppRoutes.outfitCaptureFlow);
  }

  void _showInsights(Map<String, dynamic> stats) {
    MonthlyInsightsDialog.show(
      context,
      totalOutfits: stats['total_outfits'] as int,
      uniqueItems: stats['unique_items'] as int,
      favoriteOccasion: stats['favorite_occasion'] as String,
      avgRating: '${stats['avg_rating']} ⭐',
    );
  }
}
