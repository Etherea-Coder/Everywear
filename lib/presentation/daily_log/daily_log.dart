import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/outfit_log_service.dart';
import '../../services/style_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/outfit_entry_card_widget.dart';
import './widgets/quick_log_button_widget.dart';
import './widgets/stats_summary_widget.dart';

class DailyLog extends StatefulWidget {
  const DailyLog({Key? key}) : super(key: key);

  @override
  State<DailyLog> createState() => _DailyLogState();
}

class _DailyLogState extends State<DailyLog> {
  final OutfitLogService _outfitLogService = OutfitLogService();
  final WeatherService _weatherService = WeatherService();
  final StyleService _styleService = StyleService();

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _todayEntries = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
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
      _outfitLogService.fetchOutfitLogsForDate(_selectedDate),
      _outfitLogService.fetchMonthlyStats(_selectedDate),
      _weatherService.getCurrentWeather(),
      _styleService.fetchUpcomingEvents(),
    ]);

    if (mounted) {
      setState(() {
        _todayEntries = results[0] as List<Map<String, dynamic>>;
        _monthlyStats = results[1] as Map<String, dynamic>;
        _weather = (results[2] as Map<String, dynamic>?) ?? {};
        _upcomingEvents = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
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
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
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
    if (c.contains('sun') || c.contains('clear')) {
      return '😎 Perfect for light layers';
    }
    if (c.contains('cloud')) return '🌤 A light jacket would work well';
    if (c.contains('wind')) return '💨 Try a fitted outfit today';
    return '👗 Dress for your day ahead';
  }

  // ── TODAY SUGGESTION ────────────────────────────────────
  Widget _buildTodaySuggestionCard(ThemeData theme) {
    final suggestion = _getTodaySuggestion();
    final subtitle = _getTodaySuggestionSubtitle();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Outfit",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            suggestion,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showQuickLogOptions,
                  icon: const Icon(Icons.checkroom_outlined),
                  label: const Text('Log outfit'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.4.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _refreshSuggestion,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.4.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTodaySuggestion() {
    final condition = (_weather['condition'] ?? '').toString().toLowerCase();
    final hasLoggedToday = _todayEntries.isNotEmpty;

    if (condition.contains('rain')) {
      return hasLoggedToday
          ? 'You already logged a look today. If you head out again, a water-friendly outer layer would be a smart addition.'
          : 'Go for a practical outfit today with a light waterproof layer and shoes that can handle wet weather comfortably.';
    }

    if (condition.contains('snow')) {
      return hasLoggedToday
          ? 'Your outfit is logged for today. If you need a second look, focus on warmth with extra layering and a cozy outer piece.'
          : 'Build today’s outfit around warm layers and a comfortable outerwear piece. Keep the base simple and insulating.';
    }

    if (condition.contains('sun') || condition.contains('clear')) {
      return hasLoggedToday
          ? 'You already have today covered. If you switch later, keep the silhouette light and breathable for the clearer weather.'
          : 'A lighter look would work well today. Start with breathable basics and add one polished layer if you want extra structure.';
    }

    if (condition.contains('cloud')) {
      return hasLoggedToday
          ? 'You have already logged today’s outfit. A light jacket or overshirt would still be a good add-on if the temperature drops.'
          : 'Today is ideal for easy layering. Try a balanced outfit with a simple base and one light outer layer.';
    }

    return hasLoggedToday
        ? 'You already logged an outfit today. If you want a second option later, keep it versatile and comfortable for the rest of the day.'
        : 'Choose something comfortable, easy to move in, and adaptable through the day. A balanced everyday outfit will work best.';
  }

  String _getTodaySuggestionSubtitle() {
    if (_todayEntries.isNotEmpty) {
      return 'Based on today’s weather and your current activity';
    }
    return 'A simple daily suggestion to get you started';
  }

  void _refreshSuggestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion refreshed')),
    );
    setState(() {});
  }

  // ── QUICK TIP ───────────────────────────────────────────
  Widget _buildQuickTipCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tip',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _getQuickTip(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQuickTip() {
    final totalOutfits = _monthlyStats['totalOutfits'] as int? ?? 0;
    final favoriteOccasion =
        (_monthlyStats['favoriteOccasion'] ?? 'Everyday').toString();

    if (totalOutfits == 0) {
      return 'Start logging your outfits regularly to unlock more personal style patterns and smarter daily guidance.';
    }

    if (totalOutfits < 5) {
      return 'You are building your outfit history. A few more logs will help the app understand your habits much better.';
    }

    return 'Your most common occasion this month is $favoriteOccasion. Keep one reliable version of that look ready for busy days.';
    }

  // ── UPCOMING EVENT ──────────────────────────────────────
  Widget _buildUpcomingEventCard(ThemeData theme) {
    if (_upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final event = _upcomingEvents.first;
    final date = DateTime.parse(event['event_date']);
    final daysLeft = date.difference(DateTime.now()).inDays;
    final eventType = event['event_type'] as String? ?? 'Other';
    final dressCode = event['dress_code'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Event',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  event['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  daysLeft <= 0
                      ? 'Today · $eventType'
                      : daysLeft == 1
                          ? 'Tomorrow · $eventType'
                          : 'In $daysLeft days · $eventType',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (dressCode != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.4.h),
                    child: Text(
                      'Dress code: $dressCode',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // ── SECTION HEADER ──────────────────────────────────────
  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    IconData icon, {
    VoidCallback? onTap,
    String? actionLabel,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Today',
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _loadData,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.only(top: 2.h, bottom: 12.h),
                children: [
                  _buildTodaySuggestionCard(theme),
                  SizedBox(height: 2.h),
                  _buildWeatherCard(theme),
                  SizedBox(height: 2.h),
                  _buildQuickTipCard(theme),
                  if (_upcomingEvents.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    _buildUpcomingEventCard(theme),
                  ],
                  SizedBox(height: 3.h),
                  _buildSectionHeader(
                    theme,
                    "Today's Log",
                    Icons.checkroom_outlined,
                    actionLabel: 'See month',
                    onTap: _showInsights,
                  ),
                  SizedBox(height: 1.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: StatsSummaryWidget(
                      totalOutfits: _monthlyStats['totalOutfits'] as int,
                      uniqueItems: _monthlyStats['uniqueItems'] as int,
                      favoriteOccasion:
                          _monthlyStats['favoriteOccasion'] as String,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _todayEntries.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Nothing logged yet today',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              'Use the quick log button to save today’s outfit and build your style history.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            const Text('This Month'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightRow(
              'Total Outfits',
              '${_monthlyStats['totalOutfits']}',
            ),
            _buildInsightRow(
              'Unique Items',
              '${_monthlyStats['uniqueItems']}',
            ),
            _buildInsightRow(
              'Favorite Occasion',
              '${_monthlyStats['favoriteOccasion']}',
            ),
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
}