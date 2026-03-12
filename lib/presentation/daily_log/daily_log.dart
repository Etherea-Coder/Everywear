import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/outfit_log_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/calendar_header_widget.dart';
import './widgets/outfit_entry_card_widget.dart';
import './widgets/quick_log_button_widget.dart';
import './widgets/stats_summary_widget.dart';

class DailyLog extends StatefulWidget {
  const DailyLog({Key? key}) : super(key: key);

  @override
  State<DailyLog> createState() => _DailyLogState();
}

class _DailyLogState extends State<DailyLog> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = 'calendar';

  final OutfitLogService _outfitLogService = OutfitLogService();
  final WeatherService _weatherService = WeatherService();

  List<Map<String, dynamic>> _todayEntries = [];
  Map<String, List<Map<String, dynamic>>> _monthEntries = {};
  Map<String, dynamic> _monthlyStats = {
    'totalOutfits': 0,
    'uniqueItems': 0,
    'favoriteOccasion': 'None',
  };
  Map<String, dynamic> _weather = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _loadEntriesForDate(_selectedDate),
      _loadMonthData(_focusedMonth),
      _weatherService.getCurrentWeather(),
    ]);
    if (mounted) {
      setState(() {
        _weather = (results[2] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEntriesForDate(DateTime date) async {
    final entries = await _outfitLogService.fetchOutfitLogsForDate(date);
    if (mounted) {
      setState(() => _todayEntries = entries);
    }
  }

  Future<void> _loadMonthData(DateTime month) async {
    final dates = await _outfitLogService.fetchLoggedDatesForMonth(month);
    final stats = await _outfitLogService.fetchMonthlyStats(month);

    if (mounted) {
      setState(() {
        _monthlyStats = stats;
        // Build month entries map (just keys, for calendar dots)
        _monthEntries = {
          for (final date in dates) date: [],
        };
      });
    }
  }

  // ── WEATHER ─────────────────────────────────────────────
  Widget _buildWeatherCard(ThemeData theme) {
    final temp = _weather['temperature'] ?? '--';
    final condition = _weather['condition'] ?? 'Loading...';
    final location = _weather['location'] ?? '';
    final unit = _weather['unit'] ?? '°C';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny, color: Colors.white, size: 48),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temp$unit · $condition',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getWeatherTip(condition),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherTip(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain')) return '🌂 Bring a waterproof layer today';
    if (c.contains('snow')) return '🧥 Layer up, stay warm';
    if (c.contains('sun') || c.contains('clear')) return '😎 Perfect for light layers';
    if (c.contains('cloud')) return '🌤 A light jacket would work well';
    if (c.contains('wind')) return '💨 Try a fitted outfit today';
    return '👗 Dress for your day ahead';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
            icon: Icon(
              Icons.insights,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showInsights,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Weather Card
            _buildWeatherCard(theme),
            SizedBox(height: 2.h),
            // Calendar
            CalendarHeaderWidget(
              focusedMonth: _focusedMonth,
              selectedDate: _selectedDate,
              outfitEntries: _monthEntries,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                _loadEntriesForDate(date);
              },
              onMonthChanged: (month) {
                setState(() => _focusedMonth = month);
                _loadMonthData(month);
              },
            ),

            // Stats
            StatsSummaryWidget(
              totalOutfits: _monthlyStats['totalOutfits'] as int,
              uniqueItems: _monthlyStats['uniqueItems'] as int,
              favoriteOccasion: _monthlyStats['favoriteOccasion'] as String,
            ),

            // Outfit Entries
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _todayEntries.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          itemCount: _todayEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _todayEntries[index];
                            return OutfitEntryCardWidget(
                              entry: _formatEntry(entry),
                              onEdit: () => _editEntry(entry),
                              onDelete: () => _deleteEntry(entry['id']),
                              onRepeat: () => _repeatEntry(entry['id']),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: QuickLogButtonWidget(
        onQuickLog: _showQuickLogOptions,
        onFullLog: _navigateToFullLog,
      ),
    );
  }

  /// Format Supabase entry for the card widget
  Map<String, dynamic> _formatEntry(Map<String, dynamic> entry) {
    final items = (entry['outfit_items'] as List<dynamic>? ?? [])
        .map((oi) => (oi['wardrobe_items']?['name'] ?? 'Unknown') as String)
        .toList();

    final imageUrl = (entry['outfit_items'] as List<dynamic>? ?? [])
        .map((oi) => oi['wardrobe_items']?['image_url'] as String?)
        .firstWhere((url) => url != null && url.isNotEmpty, orElse: () => null);

    final wornDate = DateTime.parse(entry['worn_date']);

    return {
      'id': entry['id'],
      'time': DateFormat('hh:mm a').format(wornDate),
      'occasion': entry['occasion'] ?? 'Outfit',
      'items': items,
      'imageUrl': imageUrl ?? '',
      'semanticLabel': entry['outfit_name'] ?? 'Outfit',
      'rating': entry['rating'] ?? 0,
      'notes': entry['notes'] ?? '',
    };
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

  void _showQuickLogOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
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
              title: 'Repeat Last Outfit',
              subtitle: 'Log your most recent outfit again',
              onTap: () {
                Navigator.pop(context);
                _repeatLastOutfit();
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
    final navigator = Navigator.of(context);
    navigator.pushNamed(AppRoutes.outfitCaptureFlow).then((_) {
      _loadData();
    });
  }

  Future<void> _repeatLastOutfit() async {
    if (_todayEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recent outfit to repeat')),
      );
      return;
    }
    await _repeatEntry(_todayEntries.first['id']);
  }

  Future<void> _repeatEntry(String outfitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat Outfit'),
        content: const Text('Log this outfit again for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repeat'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newId = await _outfitLogService.repeatOutfitLog(outfitId);
    if (newId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit repeated for today!')),
      );
      _loadData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to repeat outfit')),
      );
    }
  }

  Future<void> _editEntry(Map<String, dynamic> entry) async {
    final occasionController = TextEditingController(
      text: entry['occasion'] ?? '',
    );
    final notesController = TextEditingController(text: entry['notes'] ?? '');
    int rating = entry['rating'] ?? 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Outfit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: occasionController,
                decoration: const InputDecoration(labelText: 'Occasion'),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Text('Rating: ', style: TextStyle(fontSize: 14.sp)),
                  ...List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => rating = index + 1),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _outfitLogService.updateOutfitLog(
                  outfitId: entry['id'],
                  occasion: occasionController.text,
                  notes: notesController.text,
                  rating: rating,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Outfit updated!')),
                  );
                  _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: const Text('Are you sure you want to delete this outfit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _outfitLogService.deleteOutfitLog(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit deleted')),
      );
      _loadData();
    }
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
            _buildInsightRow(
                'Total Outfits', '${_monthlyStats['totalOutfits']}'),
            _buildInsightRow('Unique Items', '${_monthlyStats['uniqueItems']}'),
            _buildInsightRow(
                'Favorite Occasion', '${_monthlyStats['favoriteOccasion']}'),
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
          Text(label,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
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
}
