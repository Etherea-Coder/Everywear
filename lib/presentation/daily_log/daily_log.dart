import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/calendar_header_widget.dart';
import './widgets/outfit_entry_card_widget.dart';
import './widgets/quick_log_button_widget.dart';
import './widgets/stats_summary_widget.dart';

/// Daily Log Screen - Track daily outfit choices and wearing patterns
/// Displays calendar view of logged outfits, statistics, and quick logging options.
/// Helps users understand their wardrobe usage and identify neglected items.
class DailyLog extends StatefulWidget {
  const DailyLog({Key? key}) : super(key: key);

  @override
  State<DailyLog> createState() => _DailyLogState();
}

class _DailyLogState extends State<DailyLog> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = 'calendar'; // 'calendar' or 'list'

  // Mock data for outfit entries
  final Map<String, List<Map<String, dynamic>>> _outfitEntries = {
    '2026-01-12': [
      {
        'id': '1',
        'time': '09:30 AM',
        'occasion': 'Work Meeting',
        'items': ['Blue Blazer', 'White Shirt', 'Black Trousers'],
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_15c832cbe-1767853952825.png',
        'semanticLabel':
            'Professional outfit with blue blazer and white shirt on hanger',
        'rating': 4,
        'notes': 'Felt confident and professional',
      },
    ],
    '2026-01-11': [
      {
        'id': '2',
        'time': '02:00 PM',
        'occasion': 'Casual Outing',
        'items': ['Denim Jacket', 'Graphic Tee', 'Jeans'],
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1a40c7fe0-1764769079439.png',
        'semanticLabel': 'Casual denim outfit with graphic tee laid flat',
        'rating': 5,
        'notes': 'Perfect for weekend vibes',
      },
    ],
    '2026-01-10': [
      {
        'id': '3',
        'time': '10:00 AM',
        'occasion': 'Gym Session',
        'items': ['Sports Bra', 'Leggings', 'Running Shoes'],
        'imageUrl': 'https://images.unsplash.com/photo-1726195222148-fc8a7e7f37fa',
        'semanticLabel': 'Athletic wear with black leggings and sports top',
        'rating': 4,
        'notes': 'Comfortable and breathable',
      },
      {
        'id': '4',
        'time': '06:30 PM',
        'occasion': 'Dinner Date',
        'items': ['Little Black Dress', 'Heels', 'Clutch'],
        'imageUrl':
            'https://images.unsplash.com/photo-1695149870901-88a563e7a281',
        'semanticLabel': 'Elegant black dress on mannequin with accessories',
        'rating': 5,
        'notes': 'Received many compliments!',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final todayEntries = _outfitEntries[selectedDateKey] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Daily Log',
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == 'calendar' ? Icons.list : Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'calendar' ? 'list' : 'calendar';
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
            onPressed: _showInsights,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Header
          CalendarHeaderWidget(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            outfitEntries: _outfitEntries,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
            onMonthChanged: (month) {
              setState(() => _focusedMonth = month);
            },
          ),

          // Stats Summary
          StatsSummaryWidget(
            totalOutfits: _getTotalOutfitsThisMonth(),
            uniqueItems: _getUniqueItemsThisMonth(),
            favoriteOccasion: _getFavoriteOccasion(),
          ),

          // Outfit Entries List
          Expanded(
            child: todayEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: todayEntries.length,
                    itemBuilder: (context, index) {
                      return OutfitEntryCardWidget(
                        entry: todayEntries[index],
                        onEdit: () => _editEntry(todayEntries[index]),
                        onDelete: () => _deleteEntry(todayEntries[index]['id']),
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

  Widget _buildEmptyState() {
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

  int _getTotalOutfitsThisMonth() {
    int count = 0;
    _outfitEntries.forEach((key, entries) {
      final date = DateTime.parse(key);
      if (date.month == _focusedMonth.month &&
          date.year == _focusedMonth.year) {
        count += entries.length;
      }
    });
    return count;
  }

  int _getUniqueItemsThisMonth() {
    Set<String> uniqueItems = {};
    _outfitEntries.forEach((key, entries) {
      final date = DateTime.parse(key);
      if (date.month == _focusedMonth.month &&
          date.year == _focusedMonth.year) {
        for (var entry in entries) {
          uniqueItems.addAll(List<String>.from(entry['items']));
        }
      }
    });
    return uniqueItems.length;
  }

  String _getFavoriteOccasion() {
    Map<String, int> occasionCount = {};
    _outfitEntries.forEach((key, entries) {
      final date = DateTime.parse(key);
      if (date.month == _focusedMonth.month &&
          date.year == _focusedMonth.year) {
        for (var entry in entries) {
          final occasion = entry['occasion'] as String;
          occasionCount[occasion] = (occasionCount[occasion] ?? 0) + 1;
        }
      }
    });

    if (occasionCount.isEmpty) return 'None';

    return occasionCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  void _showQuickLogOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
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
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Capture your outfit now',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.outfitCaptureFlow);
              },
            ),
            _buildQuickOption(
              icon: Icons.history,
              title: 'Log Previous Outfit',
              subtitle: 'Add outfit from earlier today',
              onTap: () {
                Navigator.pop(context);
                _navigateToFullLog();
              },
            ),
            _buildQuickOption(
              icon: Icons.repeat,
              title: 'Repeat Outfit',
              subtitle: 'Log a previously worn outfit',
              onTap: () {
                Navigator.pop(context);
                _showRepeatOutfitDialog();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOption({
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

  void _navigateToFullLog() {
    // Navigate to full outfit logging screen
    Navigator.pushNamed(context, AppRoutes.outfitCaptureFlow);
  }

  void _showRepeatOutfitDialog() {
    // Show dialog to select previous outfit
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat Outfit'),
        content: const Text(
          'This feature will show your previous outfits to quickly log again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInsights() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 2.w),
            const Text('Monthly Insights'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightRow('Total Outfits', '${_getTotalOutfitsThisMonth()}'),
            _buildInsightRow('Unique Items', '${_getUniqueItemsThisMonth()}'),
            _buildInsightRow('Favorite Occasion', _getFavoriteOccasion()),
            _buildInsightRow('Avg. Rating', '4.5 ⭐'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _editEntry(Map<String, dynamic> entry) {
    // Navigate to edit screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Outfit'),
        content: const Text(
          'Edit functionality will allow you to modify outfit details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: const Text(
          'Are you sure you want to delete this outfit entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final selectedDateKey = DateFormat(
                  'yyyy-MM-dd',
                ).format(_selectedDate);
                _outfitEntries[selectedDateKey]?.removeWhere(
                  (e) => e['id'] == id,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Outfit deleted')));
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}