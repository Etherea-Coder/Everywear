import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/style_service.dart';
import '../../services/weather_service.dart';

class SmartSuggestions extends StatefulWidget {
  const SmartSuggestions({Key? key}) : super(key: key);

  @override
  State<SmartSuggestions> createState() => _SmartSuggestionsState();
}

class _SmartSuggestionsState extends State<SmartSuggestions> {
  final StyleService _styleService = StyleService();
  final WeatherService _weatherService = WeatherService();

  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _challenges = [];
  Map<String, dynamic> _insights = {};
  Map<String, dynamic>? _quizResult;
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
      _styleService.fetchUpcomingEvents(),
      _styleService.fetchChallenges(),
      _styleService.fetchStyleInsights(),
      _styleService.fetchQuizResult(),
      _weatherService.getCurrentWeather(),
    ]);
    if (mounted) {
      setState(() {
        _events = results[0] as List<Map<String, dynamic>>;
        _challenges = results[1] as List<Map<String, dynamic>>;
        _insights = results[2] as Map<String, dynamic>;
        _quizResult = results[3] as Map<String, dynamic>?;
        _weather = (results[4] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              title: Text('Style', style: theme.textTheme.headlineMedium),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                  onPressed: _loadData,
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Weather card
                    _buildWeatherCard(theme),
                    SizedBox(height: 3.h),
                    // Events section
                    _buildSectionHeader(theme, 'Events', Icons.event,
                        onAdd: _showAddEventDialog),
                    SizedBox(height: 1.h),
                    _buildEventsSection(theme),
                    SizedBox(height: 3.h),
                    // Challenges section
                    _buildSectionHeader(theme, 'Challenges', Icons.flag),
                    SizedBox(height: 1.h),
                    _buildChallengesSection(theme),
                    SizedBox(height: 3.h),
                    // Style Quiz section
                    _buildQuizSection(theme),
                    SizedBox(height: 3.h),
                    // Insights section
                    _buildSectionHeader(theme, 'Style Insights', Icons.insights),
                    SizedBox(height: 1.h),
                    _buildInsightsSection(theme),
                    SizedBox(height: 10.h),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── WEATHER ─────────────────────────────────────────────
  Widget _buildWeatherCard(ThemeData theme) {
    final temp = _weather['temperature'] ?? '--';
    final condition = _weather['condition'] ?? 'Loading...';
    final location = _weather['location'] ?? '';
    final unit = _weather['unit'] ?? '°F';

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

  // ── EVENTS ──────────────────────────────────────────────
  Widget _buildEventsSection(ThemeData theme) {
    if (_events.isEmpty) {
      return _buildEmptyCard(
        theme,
        icon: Icons.event_available,
        title: 'No upcoming events',
        subtitle: 'Add an event to get outfit suggestions',
        actionLabel: 'Add Event',
        onAction: _showAddEventDialog,
      );
    }

    return Column(
      children: _events.map((event) => _buildEventCard(theme, event)).toList(),
    );
  }

  Widget _buildEventCard(ThemeData theme, Map<String, dynamic> event) {
    final date = DateTime.parse(event['event_date']);
    final daysLeft = date.difference(DateTime.now()).inDays;
    final dateStr = DateFormat('MMM dd').format(date);
    final eventType = event['event_type'] as String? ?? 'Other';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    _buildChip(theme, _getEventIcon(eventType) + ' ' + eventType),
                    SizedBox(width: 2.w),
                    if (event['dress_code'] != null)
                      _buildChip(theme, event['dress_code']),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysLeft == 0 ? 'Today!' :
                daysLeft == 1 ? 'Tomorrow' : 'In $daysLeft days',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: daysLeft <= 3
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              GestureDetector(
                onTap: () => _deleteEvent(event['id']),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'wedding': return '💍';
      case 'dinner': return '🍽';
      case 'work': return '💼';
      case 'party': return '🎉';
      case 'travel': return '✈️';
      case 'sport': return '⚽';
      default: return '📅';
    }
  }

  // ── CHALLENGES ──────────────────────────────────────────
  Widget _buildChallengesSection(ThemeData theme) {
    if (_challenges.isEmpty) {
      return _buildEmptyCard(
        theme,
        icon: Icons.flag_outlined,
        title: 'No challenges available',
        subtitle: 'Check back soon for new style challenges',
      );
    }

    return SizedBox(
      height: 22.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _challenges.length,
        itemBuilder: (context, index) {
          return _buildChallengeCard(theme, _challenges[index]);
        },
      ),
    );
  }

  Widget _buildChallengeCard(ThemeData theme, Map<String, dynamic> challenge) {
    final isJoined = challenge['is_joined'] as bool? ?? false;
    final progress = challenge['progress'] as int? ?? 0;
    final duration = challenge['duration_days'] as int? ?? 7;

    return Container(
      width: 55.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isJoined
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isJoined
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge['category'] as String? ?? 'Style',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$duration days',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            challenge['title'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
          SizedBox(height: 0.5.h),
          Text(
            challenge['description'] as String? ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (isJoined) ...[
            LinearProgressIndicator(
              value: progress / duration,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '$progress/$duration days',
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.colorScheme.primary,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinChallenge(challenge['id']),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Join', style: TextStyle(fontSize: 12.sp)),
              ),
            ),
        ],
      ),
    );
  }

  // ── QUIZ ────────────────────────────────────────────────
  Widget _buildQuizSection(ThemeData theme) {
    final hasResult = _quizResult != null;

    return GestureDetector(
      onTap: hasResult ? null : _startQuiz,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasResult
                ? [Colors.purple.shade400, Colors.purple.shade700]
                : [Colors.orange.shade400, Colors.deepOrange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              hasResult ? '✨' : '🎯',
              style: const TextStyle(fontSize: 40),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasResult ? 'Your Style Profile' : 'Discover Your Style',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    hasResult
                        ? _quizResult!['style_profile'] as String? ?? 'Complete'
                        : 'Take the quiz to personalize your AI suggestions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasResult)
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            if (hasResult)
              TextButton(
                onPressed: _startQuiz,
                child: Text(
                  'Retake',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── INSIGHTS ────────────────────────────────────────────
  Widget _buildInsightsSection(ThemeData theme) {
    if (_insights['totalItems'] == 0) {
      return _buildEmptyCard(
        theme,
        icon: Icons.insights_outlined,
        title: 'No insights yet',
        subtitle: 'Add items to your wardrobe to see your style insights',
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '👗',
                label: 'Total Items',
                value: '${_insights['totalItems']}',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '📊',
                label: 'Outfits Logged',
                value: '${_insights['totalOutfitsLogged']}',
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '🏆',
                label: 'Top Category',
                value: '${_insights['topCategory']}',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '🎯',
                label: 'Top Occasion',
                value: '${_insights['topOccasion']}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(ThemeData theme, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Text(icon, style: const TextStyle(fontSize: 28)),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon,
      {VoidCallback? onAdd}) {
    return Row(
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
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          SizedBox(height: 1.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  // ── ACTIONS ─────────────────────────────────────────────
  void _showAddEventDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedType = 'Dinner';
    String? dressCode;

    final eventTypes = ['Wedding', 'Dinner', 'Work', 'Party', 'Travel', 'Sport', 'Other'];
    final dressCodes = ['Casual', 'Smart Casual', 'Formal', 'Black Tie', 'Sporty'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Add Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 2.h),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    hintText: 'e.g. Sarahs Wedding',
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
                SizedBox(height: 2.h),
                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                // Event type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: eventTypes.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setSheetState(() => selectedType = v!),
                ),
                SizedBox(height: 2.h),
                // Dress code
                DropdownButtonFormField<String>(
                  value: dressCode,
                  decoration: const InputDecoration(
                    labelText: 'Dress Code (optional)',
                    prefixIcon: Icon(Icons.checkroom),
                  ),
                  items: dressCodes.map((d) =>
                    DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setSheetState(() => dressCode = v),
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      final result = await _styleService.addEvent(
                        title: titleController.text.trim(),
                        eventDate: selectedDate,
                        eventType: selectedType,
                        dressCode: dressCode,
                      );
                      if (result != null) _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Event'),
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Remove this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _styleService.deleteEvent(eventId);
      _loadData();
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    final success = await _styleService.joinChallenge(challengeId);
    if (success) _loadData();
  }

  void _startQuiz() {
    _showQuizDialog();
  }

  void _showQuizDialog() {
    final questions = [
      {
        'question': 'What is your go-to style?',
        'options': ['Casual & Comfy', 'Classic & Elegant', 'Bold & Trendy', 'Sporty & Active'],
      },
      {
        'question': 'Which colors do you wear most?',
        'options': ['Neutrals (black, white, beige)', 'Earth tones (brown, green)', 'Bright & bold colors', 'Pastels & soft tones'],
      },
      {
        'question': 'What is your style goal?',
        'options': ['Look more professional', 'Be more creative', 'Simplify my wardrobe', 'Feel more confident'],
      },
      {
        'question': 'How do you feel about fashion trends?',
        'options': ['I follow them closely', 'I pick what suits me', 'I prefer timeless pieces', 'I dont really care'],
      },
    ];

    int currentQuestion = 0;
    final Map<String, String> answers = {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final q = questions[currentQuestion];
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style Quiz ${currentQuestion + 1}/${questions.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                LinearProgressIndicator(
                  value: (currentQuestion + 1) / questions.length,
                ),
                const SizedBox(height: 8),
                Text(q['question'] as String),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: (q['options'] as List<String>).map((option) =>
                ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: answers[q['question']],
                    onChanged: (v) => setDialogState(() => answers[q['question'] as String] = v!),
                  ),
                  onTap: () => setDialogState(() => answers[q['question'] as String] = option),
                ),
              ).toList(),
            ),
            actions: [
              if (currentQuestion > 0)
                TextButton(
                  onPressed: () => setDialogState(() => currentQuestion--),
                  child: const Text('Back'),
                ),
              ElevatedButton(
                onPressed: answers[q['question']] == null ? null : () async {
                  if (currentQuestion < questions.length - 1) {
                    setDialogState(() => currentQuestion++);
                  } else {
                    Navigator.pop(context);
                    final profile = _determineStyleProfile(answers);
                    await _styleService.saveQuizResult(
                      styleProfile: profile,
                      preferredColors: [answers[questions[1]['question']] ?? ''],
                      styleGoals: [answers[questions[2]['question']] ?? ''],
                      answers: answers,
                    );
                    _loadData();
                  }
                },
                child: Text(currentQuestion < questions.length - 1 ? 'Next' : 'Finish'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _determineStyleProfile(Map<String, String> answers) {
    final style = answers.values.join(' ').toLowerCase();
    if (style.contains('elegant') || style.contains('professional')) return 'Classic Elegance';
    if (style.contains('bold') || style.contains('trendy')) return 'Bold & Trendy';
    if (style.contains('sport') || style.contains('active')) return 'Active & Sporty';
    if (style.contains('simple') || style.contains('minimali')) return 'Minimalist';
    return 'Casual Chic';
  }
}
