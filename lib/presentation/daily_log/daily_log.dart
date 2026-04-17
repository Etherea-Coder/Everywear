import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/outfit_log_service.dart';
import '../home_screen/home_screen.dart';
import '../../services/style_service.dart';
import '../../services/today_suggestion_service.dart';
import '../../services/weather_service.dart';
import '../../services/supabase_service.dart';
import '../../services/wardrobe_service.dart';
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
  /// Shorthand so all methods can use `loc.xxx` without repeating
  /// AppLocalizations.of(context) on every line.
  AppLocalizations get loc => AppLocalizations.of(context);

  DateTime _selectedDate = DateTime.now();

  String _displayName = '';

  final OutfitLogService _outfitLogService = OutfitLogService();
  final WeatherService _weatherService = WeatherService();
  final StyleService _styleService = StyleService();
  final TodaySuggestionService _todaySuggestionService =
      TodaySuggestionService();
  final WardrobeService _wardrobeService = WardrobeService();

  List<Map<String, dynamic>> _wardrobeItems = [];

  List<Map<String, dynamic>> _todayEntries = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  Map<String, dynamic>? _quizResult;
  bool _isAISuggestionLoading = false;

  Map<String, dynamic> _monthlyStats = {
    'totalOutfits': 0,
    'uniqueItems': 0,
    'favoriteOccasion': 'None',
  };

  Map<String, dynamic> _weather = {};
  bool _isLoading = true;

  String? _selectedOccasion;
  String? _selectedMood;

  final List<String> _occasions = [
    'Work',
    'Casual',
    'Dinner',
    'Event',
    'Travel',
  ];

  final List<String> _moods = [
    'Casual',
    'Polished',
    'Comfort',
    'Bold',
    'Surprise',
  ];

  Map<String, dynamic> _suggestedOutfit = {
    'title': '',
    'description': '',
    'anchor': {'slot': 'anchor', 'name': '', 'imageUrl': '', 'category': ''},
    'items': [
      {'slot': 'top',    'name': '', 'imageUrl': '', 'category': ''},
      {'slot': 'bottom', 'name': '', 'imageUrl': '', 'category': ''},
      {'slot': 'shoes',  'name': '', 'imageUrl': '', 'category': ''},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load user's display name
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user != null) {
        // Try user_profiles first
        final response = await SupabaseService.instance.client
            .from('user_profiles')
            .select('display_name')
            .eq('id', user.id)
            .maybeSingle();
        if (response != null && response['display_name'] != null) {
          _displayName = response['display_name'].toString();
        } else {
          // Fallback to auth metadata
          final meta = user.userMetadata;
          _displayName = meta?['full_name'] as String? ??
              meta?['name'] as String? ??
              user.email?.split('@').first ?? '';
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Display name load failed: $e');
    }

    try {
      // Important: time out individual calls so the page never spins forever
      // if a permission prompt / network request / RPC hangs.
      final results = await Future.wait([
        _outfitLogService
            .fetchOutfitLogsForDate(_selectedDate)
            .timeout(const Duration(seconds: 12), onTimeout: () => <Map<String, dynamic>>[])
            .catchError((_) => <Map<String, dynamic>>[]),
        _outfitLogService
            .fetchMonthlyStats(_selectedDate)
            .timeout(const Duration(seconds: 12), onTimeout: () => <String, dynamic>{})
            .catchError((_) => <String, dynamic>{}),
        _weatherService
            .getCurrentWeather()
            .timeout(const Duration(seconds: 12), onTimeout: () => <String, dynamic>{})
            .catchError((_) => <String, dynamic>{}),
        _styleService
            .fetchUpcomingEvents()
            .timeout(const Duration(seconds: 12), onTimeout: () => <Map<String, dynamic>>[])
            .catchError((_) => <Map<String, dynamic>>[]),
        _styleService
            .fetchQuizResult()
            .timeout(const Duration(seconds: 12), onTimeout: () => null)
            .catchError((_) => null),
        _wardrobeService
            .fetchWardrobeItems()
            .timeout(const Duration(seconds: 12), onTimeout: () => <Map<String, dynamic>>[])
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _todayEntries   = results[0] as List<Map<String, dynamic>>;
          _monthlyStats   = results[1] as Map<String, dynamic>;
          _weather        = (results[2] as Map<String, dynamic>?) ?? {};
          _upcomingEvents = results[3] as List<Map<String, dynamic>>;
          _quizResult     = results[4] as Map<String, dynamic>?;
          _wardrobeItems  = results[5] as List<Map<String, dynamic>>;
          _generateSuggestion();
          _isLoading = false;
        });
        _loadAISuggestion();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Daily log load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateSuggestion() {
    final condition = (_weather['condition'] ?? '').toString().toLowerCase();

    String anchorName = loc.itemDenimJacket;
    String topName = loc.itemWhiteTee;
    String bottomName = loc.itemBlackJeans;
    String shoesName = loc.itemSneakers;
    String description = loc.fallbackSuggestionDesc;

    if (_selectedOccasion == 'Work') {
      anchorName = loc.itemNavyBlazer;
      topName = _selectedMood == 'Comfort' ? loc.itemSoftKnitTop : loc.itemWhiteShirt;
      bottomName =
          _selectedMood == 'Casual' ? loc.itemDarkJeans : loc.itemTailoredTrousers;
      shoesName = _selectedMood == 'Comfort' ? loc.itemMinimalLoafers : loc.itemLeatherShoes;
      description = loc.workSuggestionDesc;
    } else if (_selectedOccasion == 'Dinner') {
      anchorName = loc.itemStatementJacket;
      topName = loc.itemSilkTop;
      bottomName = loc.itemDarkTrousers;
      shoesName = _selectedMood == 'Comfort' ? loc.itemLowHeels : loc.itemChelseaBoots;
      description = loc.dinnerSuggestionDesc;
    } else if (_selectedOccasion == 'Travel') {
      anchorName = loc.itemLightOvershirt;
      topName = loc.itemBreathableTee;
      bottomName = loc.itemRelaxedPants;
      shoesName = loc.itemComfortSneakers;
      description = loc.travelSuggestionDesc;
    } else if (_selectedOccasion == 'Event') {
      anchorName = loc.itemStructuredBlazer;
      topName = loc.itemRefinedTop;
      bottomName = loc.itemTailoredBottoms;
      shoesName = loc.itemDressShoes;
      description = loc.eventSuggestionDesc;
    } else {
      if (condition.contains('rain')) {
        anchorName = loc.itemWaterproofJacket;
        topName = loc.itemSoftTee;
        bottomName = loc.itemDarkJeans;
        shoesName = loc.itemWeatherproofSneakers;
        description = loc.rainSuggestionDesc;
      } else if (condition.contains('sun') || condition.contains('clear')) {
        anchorName = loc.itemLightCardigan;
        topName = loc.itemCottonTee;
        bottomName = loc.itemRelaxedTrousers;
        shoesName = loc.itemWhiteSneakers;
        description = loc.sunSuggestionDesc;
      } else if (_selectedMood == 'Polished') {
        anchorName = loc.itemTailoredOvershirt;
        topName = loc.itemCleanNeutralTop;
        bottomName = loc.itemStraightTrousers;
        shoesName = loc.itemMinimalLoafers;
        description = loc.polishedSuggestionDesc;
      } else if (_selectedMood == 'Bold') {
        anchorName = loc.itemStatementLayer;
        topName = loc.itemContrastTop;
        bottomName = loc.itemDarkDenim;
        shoesName = loc.itemBoldSneakers;
        description = loc.boldSuggestionDesc;
      }
    }

    if (_selectedMood == 'Surprise') {
      anchorName = loc.itemDenimJacket;
      topName = loc.itemCleanNeutralTop;
      bottomName = loc.itemRelaxedPants;
      shoesName = loc.itemChunkySneakers;
      description = loc.surpriseSuggestionDesc;
    }

    // Preserve existing imageUrls by matching names against wardrobe
    _suggestedOutfit = _mergeImageUrls(
      {
        'title': loc.todaysStyleIdea,
        'description': description,
        'anchor': {
          'slot': 'anchor',
          'name': anchorName,
          'imageUrl': '',
          'category': loc.catAnchor,
        },
        'items': [
          {
            'slot': 'top',
            'name': topName,
            'imageUrl': '',
            'category': loc.catTop,
          },
          {
            'slot': 'bottom',
            'name': bottomName,
            'imageUrl': '',
            'category': loc.catBottom,
          },
          {
            'slot': 'shoes',
            'name': shoesName,
            'imageUrl': '',
            'category': loc.catShoes,
          },
        ],
      },
      _suggestedOutfit,
    );
  }

  // ─── FIX 1: Image URL preservation helpers ───────────────────────────────

  /// Tries to find a wardrobe image for [itemName], falling back to
  /// [fallbackUrl] (the URL the item already had before refresh).
  String _resolveImageUrl(String? itemName, String fallbackUrl) {
    if (itemName == null || itemName.isEmpty) return fallbackUrl;
    final name = itemName.toLowerCase();
    for (final w in _wardrobeItems) {
      final wName = (w['name'] ?? w['title'] ?? '').toString().toLowerCase();
      if (wName == name || wName.contains(name) || name.contains(wName)) {
        final url = (w['image_url'] ?? w['imageUrl'] ?? '').toString();
        if (url.isNotEmpty) return url;
      }
    }
    return fallbackUrl;
  }

  /// Overlays wardrobe-resolved (or previously loaded) imageUrls onto
  /// [newOutfit], so images never regress to empty strings on refresh.
    Map<String, dynamic> _mergeImageUrls(
    Map<String, dynamic> newOutfit,
    Map<String, dynamic> prevOutfit,
  ) {
    // --- anchor ---
    final newAnchor =
        Map<String, dynamic>.from(newOutfit['anchor'] as Map? ?? {});
    final prevAnchor =
        Map<String, dynamic>.from(prevOutfit['anchor'] as Map? ?? {});
    newAnchor['imageUrl'] = _resolveImageUrl(
      newAnchor['name'] as String?,
      (prevAnchor['imageUrl'] ?? '').toString(),
    );

    // --- items ---
    final prevItems =
        ((prevOutfit['items'] as List?)?.cast<Map<String, dynamic>>() ?? [])
            .asMap();
    final newItems =
        ((newOutfit['items'] as List?)?.cast<Map<String, dynamic>>() ?? [])
            .asMap()
            .map((i, item) {
      final mutable = Map<String, dynamic>.from(item);
      final prevUrl = (prevItems[i]?['imageUrl'] ?? '').toString();
      mutable['imageUrl'] =
          _resolveImageUrl(mutable['name'] as String?, prevUrl);
      return MapEntry(i, mutable);
    });

    return {
      ...newOutfit,
      'anchor': newAnchor,
      'items': newItems.values.toList(),
    };
  }

  Future<void> _loadAISuggestion() async {
    if (_isAISuggestionLoading) return;
    setState(() => _isAISuggestionLoading = true);

    try {
      final nextEvent =
          _upcomingEvents.isNotEmpty ? _upcomingEvents.first : null;
      final result = await _todaySuggestionService
          .fetchTodaySuggestion(
            weather: _weather,
            quizResult: _quizResult,
            nextEvent: nextEvent,
            occasion: _selectedOccasion,
            mood: _selectedMood,
          )
          .timeout(const Duration(seconds: 18), onTimeout: () => null);

      if (!mounted) return;
      setState(() {
        if (result != null) {
          // Merge imageUrls from wardrobe / previous state so they never disappear
          _suggestedOutfit = _mergeImageUrls(
            {
              'title': result['title'] ?? loc.todaysStyleIdea,
              'description': result['description'] ?? '',
              'styling_note': result['styling_note'] ?? '',
              'anchor': result['anchor'] ?? _suggestedOutfit['anchor'],
              'items': result['items'] ?? _suggestedOutfit['items'],
            },
            _suggestedOutfit,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Today suggestion load failed: $e');
    } finally {
      if (mounted) setState(() => _isAISuggestionLoading = false);
    }
  }

  Widget _buildWelcomeHeroCard(ThemeData theme) {
    final localizations = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? localizations.goodMorning
        : hour < 17
            ? localizations.goodAfternoon
            : localizations.goodEvening;
    
    // Add display name to greeting if available
    final fullGreeting = _displayName.isNotEmpty 
        ? '$greeting, $_displayName' 
        : greeting;
    
    final dayLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());

    final location = (_weather['location'] ?? '').toString();
    final condition = (_weather['condition'] ?? '').toString();
    final temp = _weather['temperature'];
    final unit = (_weather['unit'] ?? '°C').toString();
    final hasWeather = temp != null && condition.isNotEmpty;
    final weatherLabel = hasWeather ? '$temp$unit · $condition' : localizations.weatherFallbackLabel;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              weatherLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            fullGreeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          SizedBox(height: 0.6.h),
          Text(
            dayLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (location.isNotEmpty) ...[
            SizedBox(height: 0.4.h),
            Text(
              location,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Text(
            localizations.dailyLogWelcomeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard(ThemeData theme) {
    final loc = AppLocalizations.of(context);

    String getLocalizedOccasion(String occasion) {
      switch (occasion) {
        case 'Work': return loc.occasionWork;
        case 'Casual': return loc.occasionCasual;
        case 'Dinner': return loc.occasionDinner;
        case 'Event': return loc.occasionEvent;
        case 'Travel': return loc.occasionTravel;
        default: return occasion;
      }
    }

    String getLocalizedMood(String mood) {
      switch (mood) {
        case 'Casual': return loc.moodCasual;
        case 'Polished': return loc.moodPolished;
        case 'Comfort': return loc.moodComfort;
        case 'Bold': return loc.moodBold;
        case 'Surprise': return loc.moodSurprise;
        default: return mood;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.setTodaysDirection,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.6.h),
          Text(
            loc.setDirectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            loc.dressingFor,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.2.h,
            children: _occasions.map((occasion) {
              final selected = _selectedOccasion == occasion;
              return _buildWarmChoiceChip(
                theme,
                label: getLocalizedOccasion(occasion),
                selected: selected,
                onTap: () {
                  setState(() {
                    _selectedOccasion = selected ? null : occasion;
                    _generateSuggestion();
                  });
                  _loadAISuggestion();
                },
              );
            }).toList(),
          ),
          SizedBox(height: 2.2.h),
          Text(
            loc.todaysVibe,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.2.h,
            children: _moods.map((mood) {
              final selected = _selectedMood == mood;
              return _buildWarmChoiceChip(
                theme,
                label: getLocalizedMood(mood),
                selected: selected,
                onTap: () {
                  setState(() {
                    _selectedMood = selected ? null : mood;
                    _generateSuggestion();
                  });
                  _loadAISuggestion();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmChoiceChip(
    ThemeData theme, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 4.2.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                : theme.colorScheme.outline.withValues(alpha: 0.20),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.88),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    final temp = _weather['temperature'];
    final condition = _weather['condition'] ?? loc.loading;
    final location = _weather['location'] ?? '';
    final unit = _weather['unit'] ?? '°C';
    final isError = _weather['error'] == true;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -2.w,
            bottom: -2.w,
            child: Icon(
              isError ? Icons.location_off : Icons.wb_sunny_outlined,
              size: 95,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),

          // Foreground content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isError ? condition : '$temp$unit · $condition',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (location.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 0.4.h),
                  child: Text(
                    location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (!isError)
                Padding(
                  padding: EdgeInsets.only(top: 0.8.h),
                  child: Text(
                    _getWeatherTip(loc, condition),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              // ── Manual city entry when location is denied ──────────────
              if (isError)
                Padding(
                  padding: EdgeInsets.only(top: 1.0.h),
                  child: GestureDetector(
                    onTap: _showManualCityDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          loc.enterCityManually,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showManualCityDialog() async {
    final controller = TextEditingController(
      text: _weatherService.savedCity,
    );
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.enterCityTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: loc.cityHint,
            prefixIcon: const Icon(Icons.location_city_outlined),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      final result = await _weatherService.getWeatherByCity(
        controller.text.trim(),
      );
      if (mounted) {
        setState(() {
          _weather = result;
          _isLoading = false;
        });
        // Refresh AI suggestion with new weather context
        _loadAISuggestion();
      }
    }
    controller.dispose();
  }

  String _getWeatherTip(AppLocalizations loc, String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain')) return loc.weatherTipRain;
    if (c.contains('snow')) return loc.weatherTipSnow;
    if (c.contains('sun') || c.contains('clear')) return loc.weatherTipSun;
    if (c.contains('cloud')) return loc.weatherTipCloud;
    if (c.contains('wind')) return loc.weatherTipWind;
    return loc.weatherTipDefault;
  }

  String _getCategoryEmoji(String? category) {
    switch (category?.toLowerCase()) {
      case 'tops': return '👕';
      case 'bottoms': return '👖';
      case 'shoes': return '👟';
      case 'outerwear': return '🧥';
      case 'accessories': return '👜';
      case 'dresses': return '👗';
      case 'activewear': return '🏃';
      default: return '👗';
    }
  }

  Widget _buildTodaySuggestionCard(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    final anchor = _suggestedOutfit['anchor'] as Map<String, dynamic>;
    final items = (_suggestedOutfit['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.cardColor,
            theme.colorScheme.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨ ', style: TextStyle(fontSize: 18)),
                        Text(
                          _suggestedOutfit['title'] as String? ??
                              loc.todaysStyleIdea,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: 0.8.h),
                    Text(
                      _suggestedOutfit['description'] as String? ??
                          loc.simpleDailySuggestion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((_suggestedOutfit['styling_note'] as String? ?? '').isNotEmpty) ...[
            SizedBox(height: 1.6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: theme.colorScheme.secondary,
                  ),
                  SizedBox(width: 1.5.w),
                  Flexible(
                    child: Text(
                      _suggestedOutfit['styling_note'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 2.8.h),

          GestureDetector(
            onTap: () => _showSwapItemSheet(anchor),
            child: Column(
              children: [
                _buildSuggestionItemCard(
                  theme,
                  item: anchor,
                  isAnchor: true,
                ),
                SizedBox(height: 1.h),
                Text(
                  anchor['name'] as String? ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 0.4.h),
                Text(
                  loc.anchorPieceTapToSwap,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.2.h),
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
          SizedBox(height: 1.8.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                  child: GestureDetector(
                    onTap: () => _showSwapItemSheet(item),
                    child: Column(
                      children: [
                        _buildSuggestionItemCard(
                          theme,
                          item: item,
                          isAnchor: false,
                        ),
                        SizedBox(height: 0.8.h),
                        Text(
                          item['name'] as String? ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.2.h),
                        Text(
                          loc.tapToSwap,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 2.6.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showQuickLogOptions,
                  icon: const Icon(Icons.checkroom_outlined),
                  label: Text(loc.logOutfitBtn),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.45.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _generateSuggestion());
                    _loadAISuggestion();
                  },
                  icon: _isAISuggestionLoading
                      ? SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isAISuggestionLoading ? loc.loading : loc.refresh),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.45.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildSuggestionItemCard(
    ThemeData theme, {
    required Map<String, dynamic> item,
    required bool isAnchor,
  }) {
    final imageUrl = item['imageUrl'] as String? ?? '';

    return Container(
      height: isAnchor ? 18.h : 11.5.h,
      width: isAnchor ? 18.h : 11.5.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isAnchor ? 22 : 16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withValues(alpha: isAnchor ? 0.08 : 0.05),
            theme.colorScheme.secondary.withValues(alpha: isAnchor ? 0.04 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(
            alpha: isAnchor ? 0.14 : 0.10,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isAnchor ? 22 : 16),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildSuggestionFallbackIcon(
                  theme,
                  isAnchor: isAnchor,
                ),
              )
            : _buildSuggestionFallbackIcon(
                theme,
                isAnchor: isAnchor,
              ),
      ),
    );
  }

  Widget _buildSuggestionFallbackIcon(
    ThemeData theme, {
    required bool isAnchor,
  }) {
    return Center(
      child: Icon(
        Icons.checkroom,
        size: isAnchor ? 46 : 28,
        color: theme.colorScheme.secondary,
      ),
    );
  }

  Future<void> _showSwapItemSheet(Map<String, dynamic> currentItem) async {
    final loc = AppLocalizations.of(context);
    final slot = currentItem['slot'] as String? ?? 'item';

    // Ensure wardrobe is loaded
    if (_wardrobeItems.isEmpty) {
      final items = await _wardrobeService.fetchWardrobeItems();
      if (mounted) setState(() => _wardrobeItems = items);
    }
    if (!mounted) return;

    // For anchor — show category picker first, then items
    if (slot == 'anchor') {
      _showAnchorCategoryPicker(loc);
    } else {
      // For supporting slots — show items directly as before
      final alternatives = _getSwapAlternatives(slot);
      _showItemList(loc, slot, alternatives);
    }
  }

  void _showAnchorCategoryPicker(AppLocalizations loc) {
    // Get unique categories from wardrobe
    final categories = _wardrobeItems
        .map((i) => (i['category'] as String? ?? 'Other'))
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Text(
              'Choose a category',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 0.8.h),
            Text(
              'What type of anchor piece?',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: categories.map((category) {
                  return ListTile(
                    leading: Text(
                      _getCategoryEmoji(category),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${_wardrobeItems.where((i) => i['category'] == category).length} items',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Show items from this category
                      final categoryItems = _wardrobeItems
                          .where((i) => i['category'] == category)
                          .map((i) => {
                                'slot': 'anchor',
                                'name': i['name'] ?? i['title'] ?? loc.unknownItem,
                                'imageUrl': i['image_url'] ?? i['imageUrl'] ?? '',
                                'category': i['category'] ?? loc.catClothing,
                                'id': i['id'],
                              })
                          .toList();
                      _showItemList(loc, 'anchor', categoryItems);
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  void _showItemList(AppLocalizations loc, String slot, List<Map<String, dynamic>> alternatives) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Text(
              loc.swapItemTitle(_getLocalizedSlotTitle(loc, slot)),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 0.8.h),
            Text(
              loc.chooseDifferentPiece,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            if (alternatives.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    Icon(Icons.checkroom_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    SizedBox(height: 2.h),
                    Text(
                      loc.noItemsInCategory,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.addClothingItem);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(loc.addItemToWardrobe),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: alternatives.map((item) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 0.5.h),
                      leading: Container(
                        width: 13.w,
                        height: 13.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (item['imageUrl'] as String? ?? '').isNotEmpty
                              ? Image.network(
                                  item['imageUrl'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.checkroom),
                                )
                              : const Icon(Icons.checkroom),
                        ),
                      ),
                      title: Text(
                        item['name'] as String,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item['category'] as String? ?? '',
                        style: TextStyle(fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      trailing: Icon(Icons.swap_horiz,
                          color: Theme.of(context).colorScheme.primary),
                      onTap: () {
                        Navigator.pop(context);
                        _swapSuggestionItem(slot, item);
                      },
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSwapAlternatives(String slot) {
    // Match against the English category keywords stored in Supabase.
    // We never use translated strings here because wardrobe data is stored
    // in English regardless of the app's display language.
    final List<String> categoryKeywords;
    switch (slot) {
      case 'anchor':
        categoryKeywords = ['outerwear', 'jacket', 'coat', 'blazer', 'cardigan', 'overshirt', 'knitwear', 'hoodie', 'sweater'];
        break;
      case 'top':
        categoryKeywords = ['top', 'tops', 'shirt', 'blouse', 'tee', 'sweater', 'jumper', 'knitwear'];
        break;
      case 'bottom':
        categoryKeywords = ['bottom', 'bottoms', 'jeans', 'trousers', 'pants', 'skirt', 'shorts', 'denim'];
        break;
      case 'shoes':
        categoryKeywords = ['shoes', 'footwear', 'boots', 'sneakers', 'loafers', 'heels', 'trainers'];
        break;
      default:
        categoryKeywords = [];
    }

  final alternatives = _wardrobeItems.where((item) {
    if (categoryKeywords.isEmpty) return true;
    final itemCategory = (item['category'] as String? ?? '').toLowerCase();
    return categoryKeywords.any((kw) => itemCategory.contains(kw));
  }).map((item) => {
    'slot': slot,
    'name': item['name'] ?? item['title'] ?? loc.unknownItem,
    'imageUrl': item['image_url'] ?? item['imageUrl'] ?? '',
    'category': item['category'] ?? loc.catClothing,
    'id': item['id'],
  }).toList();

  if (alternatives.isNotEmpty) return alternatives;

  // Anchor fallback: show ALL wardrobe items so user is never stuck
  if (slot == 'anchor') {
    return _wardrobeItems.map((item) => {
      'slot': slot,
      'name': item['name'] ?? item['title'] ?? loc.unknownItem,
      'imageUrl': item['image_url'] ?? item['imageUrl'] ?? '',
      'category': item['category'] ?? loc.catClothing,
      'id': item['id'],
    }).toList();
  }

  return [];

  }

  String _getLocalizedSlotTitle(AppLocalizations loc, String slot) {
    switch (slot) {
      case 'anchor':
        return loc.slotAnchor;
      case 'top':
        return loc.slotTop;
      case 'bottom':
        return loc.slotBottom;
      case 'shoes':
        return loc.slotShoes;
      default:
        return loc.slotItem;
    }
  }

  void _swapSuggestionItem(String slot, Map<String, dynamic> newItem) {
    setState(() {
      if (slot == 'anchor') {
        _suggestedOutfit['anchor'] = newItem;
        
        // Re-derive supporting slots based on new anchor's category
        final category = (newItem['category'] as String? ?? '').toLowerCase();
        
        List<Map<String, dynamic>> newItems;
        
        if (category.contains('top') || category.contains('shirt') || 
            category.contains('blouse') || category.contains('tee')) {
          // Anchor is a top → suggest bottom, shoes, bag
          newItems = [
            {'slot': 'bottom', 'name': loc.itemDarkJeans, 'imageUrl': '', 'category': loc.catBottom},
            {'slot': 'shoes',  'name': loc.itemSneakers,  'imageUrl': '', 'category': loc.catShoes},
          ];
        } else if (category.contains('bottom') || category.contains('jean') || 
                  category.contains('trouser') || category.contains('skirt')) {
          // Anchor is a bottom → suggest top, shoes
          newItems = [
            {'slot': 'top',   'name': loc.itemWhiteTee,  'imageUrl': '', 'category': loc.catTop},
            {'slot': 'shoes', 'name': loc.itemSneakers,  'imageUrl': '', 'category': loc.catShoes},
          ];
        } else if (category.contains('outerwear') || category.contains('jacket') || 
                  category.contains('coat') || category.contains('blazer')) {
          // Anchor is outerwear → suggest top, bottom, shoes
          newItems = [
            {'slot': 'top',    'name': loc.itemWhiteTee,       'imageUrl': '', 'category': loc.catTop},
            {'slot': 'bottom', 'name': loc.itemDarkJeans,      'imageUrl': '', 'category': loc.catBottom},
            {'slot': 'shoes',  'name': loc.itemSneakers,       'imageUrl': '', 'category': loc.catShoes},
          ];
        } else {
          // Default — keep existing slots but clear names
          newItems = (_suggestedOutfit['items'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((i) => {...i, 'name': '', 'imageUrl': ''})
              .toList();
        }
        
        _suggestedOutfit['items'] = newItems;
        // Try to resolve wardrobe images for new items
        _suggestedOutfit = _mergeImageUrls(_suggestedOutfit, _suggestedOutfit);
        
      } else {
        // Supporting item swap — just replace that slot
        final items = (_suggestedOutfit['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final index = items.indexWhere((item) => item['slot'] == slot);
        if (index != -1) {
          items[index] = newItem;
        }
        _suggestedOutfit['items'] = items;
      }
    });
  }

  Widget _buildQuickTipCard(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.14),
        ),
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -2.w,
            bottom: -2.w,
            child: Icon(
              Icons.lightbulb_outline,
              size: 90,
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            ),
          ),

          // Foreground content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.styleTip,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.8.h),
              Text(
                _getQuickTip(loc),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getQuickTip(AppLocalizations loc) {
    final totalOutfits = _monthlyStats['totalOutfits'] as int? ?? 0;
    final favoriteOccasion =
        (_monthlyStats['favoriteOccasion'] ?? loc.occasionEveryday).toString();

    if (totalOutfits == 0) {
      return loc.styleTipNoLogs;
    }

    if (totalOutfits < 5) {
      return loc.styleTipFewLogs;
    }

    if (_selectedMood == 'Bold') {
      return loc.styleTipBold;
    }

    if (_selectedMood == 'Comfort') {
      return loc.styleTipComfort;
    }

    return loc.styleTipFavoriteOccasion(favoriteOccasion);
  }

  Widget _buildUpcomingEventCard(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    if (_upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final event = _upcomingEvents.first;
    final date = DateTime.parse(event['event_date']);
    final daysLeft = date.difference(DateTime.now()).inDays;
    final eventType = event['event_type'] as String? ?? loc.eventTypeOther;
    final dressCode = event['dress_code'] as String?;

    return GestureDetector(
      onTap: () => HomeScreen.goToTab(context, 2),
      child: Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
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
                  loc.upcomingEvent,
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
                      ? '${loc.today} · $eventType'
                      : daysLeft == 1
                          ? '${loc.tomorrow} · $eventType'
                          : '${loc.inDaysLeft(daysLeft)} · $eventType',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (dressCode != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.4.h),
                    child: Text(
                      loc.dressCodeFormat(dressCode),
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
    ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Expanded(
            child: Divider(
              indent: 12,
              thickness: 0.6,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

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
        title: loc.today,
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
                padding: EdgeInsets.only(top: 2.h, bottom: 15.h),
                children: [
                  SizedBox(height: 1.5.h),
                  
                  // Hero Section - Welcome
                  _buildWelcomeHeroCard(theme),
                  SizedBox(height: 2.h),
                  
                  // Set Today's Direction Section
                  _buildSectionTitle(theme, loc.setTodaysDirection),
                  SizedBox(height: 1.2.h),
                  _buildContextCard(theme),
                  SizedBox(height: 2.h),
                  
                  // Today's Style Idea (Main Feature)
                  _buildTodaySuggestionCard(theme),
                  SizedBox(height: 2.h),
                  
                  // Weather + Quick Tip Group
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildWeatherCard(theme)),
                      SizedBox(width: 3.w),
                      Expanded(child: _buildQuickTipCard(theme)),
                    ],
                  ),
                  if (_upcomingEvents.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    _buildUpcomingEventCard(theme),
                  ],
                  SizedBox(height: 3.h),
                  
                  // Log Section
                  _buildSectionHeader(
                    theme,
                    loc.todaysLogSection,
                    Icons.checkroom_outlined,
                    actionLabel: loc.thisMonth,
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
                      ? _buildEmptyState(theme)
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

  Map<String, dynamic> _formatEntry(Map<String, dynamic> entry) {
    final items = (entry['outfit_items'] as List<dynamic>? ?? [])
        .map((oi) => {
            'name': (oi['wardrobe_items']?['name'] ?? loc.unknown) as String,
            'imageUrl': (oi['wardrobe_items']?['image_url'] ?? '') as String,
          })
        .toList();

    final imageUrl = (entry['outfit_items'] as List<dynamic>? ?? [])
        .map((oi) => oi['wardrobe_items']?['image_url'] as String?)
        .firstWhere((url) => url != null && url.isNotEmpty, orElse: () => null);

    final wornDate = DateTime.parse(entry['worn_date']);

    return {
      'id': entry['id'],
      'time': DateFormat('hh:mm a').format(wornDate),
      'occasion': entry['occasion'] ?? loc.outfitLabel,
      'items': items,
      'imageUrl': imageUrl ?? '',
      'semanticLabel': entry['outfit_name'] ?? loc.outfitLabel,
      'rating': entry['rating'] ?? 0,
      'notes': entry['notes'] ?? '',
    };
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom_outlined,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.6.h),
            Text(
              loc.nothingLoggedToday,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              loc.quickLogPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickLogOptions() {
    // Capture all strings from the state context BEFORE entering the
    // bottom-sheet builder, which receives its own context that may not
    // carry the correct locale in some Flutter/localizations setups.
    final title         = loc.quickLogOptions;
    final photoTitle    = loc.quickLogTakePhotoTitle;
    final photoSub      = loc.quickLogTakePhotoSubtitle;
    final prevTitle     = loc.quickLogPreviousTitle;
    final prevSub       = loc.quickLogPreviousSubtitle;
    final repeatTitle   = loc.quickLogRepeatTitle;
    final repeatSub     = loc.quickLogRepeatSubtitle;
    final saveTitle     = loc.quickLogSaveDisplayedTitle;
    final saveSub       = loc.quickLogSaveDisplayedSubtitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).dividerColor,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                _buildQuickOption(
                  icon: Icons.camera_alt,
                  title: photoTitle,
                  subtitle: photoSub,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, AppRoutes.outfitCaptureFlow);
                  },
                ),
                _buildQuickOption(
                  icon: Icons.history,
                  title: prevTitle,
                  subtitle: prevSub,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _navigateToFullLog();
                  },
                ),
                _buildQuickOption(
                  icon: Icons.repeat,
                  title: repeatTitle,
                  subtitle: repeatSub,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _repeatLastOutfit();
                  },
                ),
                _buildQuickOption(
                  icon: Icons.checkroom,
                  title: saveTitle,
                  subtitle: saveSub,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _saveDisplayedOutfit();
                  },
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
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
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
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
        style: TextStyle(
          fontSize: 13.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
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
        SnackBar(content: Text(AppLocalizations.of(context).retry)),
      );
      return;
    }
    await _repeatEntry(_todayEntries.first['id']);
  }

  // ─── FIX 2: Save Displayed Outfit — logs directly, no navigation ─────────

  Future<void> _saveDisplayedOutfit() async {
    final anchor = _suggestedOutfit['anchor'] as Map<String, dynamic>?;
    final items = (_suggestedOutfit['items'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();

    if (anchor == null || items == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).noOutfitDisplayedError)),
      );
      return;
    }

    // Collect wardrobe IDs for items that were matched to real wardrobe entries
    final List<String> itemIds = [
      if (anchor['id'] != null) anchor['id'] as String,
      ...items
          .where((i) => i['id'] != null)
          .map((i) => i['id'] as String),
    ];

    // Ask the user for occasion + optional notes before saving
    String? selectedOccasion = _selectedOccasion ?? 'Casual';
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final loc = AppLocalizations.of(context);
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.checkroom,
                    color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _suggestedOutfit['title'] as String? ??
                        loc.todaysStyleIdea,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Outfit item names summary
                Text(
                  [
                    anchor['name'] as String? ?? '',
                    ...items.map((i) => i['name'] as String? ?? ''),
                  ]
                      .where((n) => n.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                // Occasion picker
                Text(loc.dressingFor,
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _occasions.map((occ) {
                    final sel = selectedOccasion == occ;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedOccasion = occ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 0.8.h),
                        decoration: BoxDecoration(
                          color: sel
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.14)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: sel
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.4)
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          occ,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: sel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: loc.notes,
                    hintText: loc.optionalNotesHint,
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 3.w, vertical: 1.2.h),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).save),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    // If no wardrobe IDs were matched, log the outfit by name only
    // (outfit_log without item links — adjust to your service API as needed)
    try {
      String? newId;

      if (itemIds.isNotEmpty) {
        newId = await _outfitLogService.logOutfitWithItems(
          wornDate: DateTime.now(),
          itemIds: itemIds,
          occasion: selectedOccasion ?? 'Casual',
          notes: notesController.text.trim(),
          outfitName:
              _suggestedOutfit['title'] as String? ?? loc.todaysStyleIdea,
        );
      } else {
        // Fallback: log outfit by name when items aren't in wardrobe yet
        newId = await _outfitLogService.logOutfitByName(
          wornDate: DateTime.now(),
          outfitName:
              _suggestedOutfit['title'] as String? ?? loc.todaysStyleIdea,
          occasion: selectedOccasion ?? 'Casual',
          notes: notesController.text.trim(),
          itemNames: [
            anchor['name'] as String? ?? '',
            ...items.map((i) => i['name'] as String? ?? ''),
          ].where((n) => n.isNotEmpty).toList(),
        );
      }

      if (newId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).outfitLoggedSuccess)),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error)),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving displayed outfit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  Future<void> _repeatEntry(String outfitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).repeatOutfit),
        content: Text(AppLocalizations.of(context).repeatOutfitQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).repeatOutfit),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newId = await _outfitLogService.repeatOutfitLog(outfitId);
    if (newId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).outfitRepeated)),
      );
      _loadData();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).error)),
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
          title: Text(AppLocalizations.of(context).editOutfit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: occasionController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).occasion),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).notes),
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Text(AppLocalizations.of(context).rating, style: TextStyle(fontSize: 14.sp)),
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                if (context.mounted) Navigator.pop(context);
                final success = await _outfitLogService.updateOutfitLog(
                  outfitId: entry['id'],
                  occasion: occasionController.text,
                  notes: notesController.text,
                  rating: rating,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).outfitUpdated)),
                  );
                  _loadData();
                }
              },
              child: Text(AppLocalizations.of(context).save),
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
        title: Text(AppLocalizations.of(context).deleteOutfit),
        content: Text(AppLocalizations.of(context).deleteOutfitConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _outfitLogService.deleteOutfitLog(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).outfitDeleted)),
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
            Text(AppLocalizations.of(context).thisMonth),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightRow(
              AppLocalizations.of(context).totalOutfits,
              '${_monthlyStats['totalOutfits']}',
            ),
            _buildInsightRow(
              AppLocalizations.of(context).uniqueItems,
              '${_monthlyStats['uniqueItems']}',
            ),
            _buildInsightRow(
              AppLocalizations.of(context).favoriteOccasion,
              '${_monthlyStats['favoriteOccasion']}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).done),
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
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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