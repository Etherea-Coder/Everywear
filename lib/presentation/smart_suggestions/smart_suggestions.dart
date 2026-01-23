import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/ai/stylist_engine_service.dart';
import '../ai_suggestions/widgets/ai_suggestion_bubble_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/neglected_items_widget.dart';
import './widgets/suggestion_card_widget.dart';

/// Smart Suggestions Screen - AI-powered outfit recommendations
/// Accessed via tab bar navigation structure
class SmartSuggestions extends StatefulWidget {
  const SmartSuggestions({Key? key}) : super(key: key);

  @override
  State<SmartSuggestions> createState() => _SmartSuggestionsState();
}

class _SmartSuggestionsState extends State<SmartSuggestions> {
  String _selectedOccasion = 'all';
  bool _isRefreshing = false;
  bool _isGeneratingAI = false;
  bool _showAIBubble = true; // Always show on initial load
  final List<String> _savedSuggestions = [];
  final StylistEngineService _stylistEngine = StylistEngineService();
  List<Map<String, dynamic>> _aiGeneratedSuggestions = [];

  // Mock weather data
  final Map<String, dynamic> _weatherData = {
    "temperature": 72,
    "condition": "Partly Cloudy",
    "icon": "partly_cloudy_day",
    "location": "San Francisco, CA",
  };

  // Mock wardrobe data (in production, load from local storage)
  final List<Map<String, dynamic>> _wardrobeItems = [
    {
      'id': 'item_001',
      'name': 'White Cotton Tee',
      'category': 'Tops',
      'color': 'White',
      'material': 'Cotton',
      'style_vibe': 'Casual',
      'wearCount': 5,
      'rating': 5.0,
      'image': 'https://images.unsplash.com/photo-1697912181230-d506d6075fd7',
      'semanticLabel': 'White cotton t-shirt on hanger',
    },
    {
      'id': 'item_002',
      'name': 'Classic Blue Jeans',
      'category': 'Bottoms',
      'color': 'Blue',
      'material': 'Denim',
      'style_vibe': 'Casual',
      'wearCount': 8,
      'rating': 4.5,
      'image': 'https://images.unsplash.com/photo-1515460023844-1d7c9785164a',
      'semanticLabel': 'Blue denim jeans folded',
    },
    {
      'id': 'item_003',
      'name': 'Navy Blazer',
      'category': 'Outerwear',
      'color': 'Blue',
      'material': 'Wool',
      'style_vibe': 'Professional',
      'wearCount': 2,
      'rating': 4.8,
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_17053e168-1766577387072.png',
      'semanticLabel': 'Navy blue blazer on hanger',
    },
    {
      'id': 'item_004',
      'name': 'Gray Dress Pants',
      'category': 'Bottoms',
      'color': 'Gray',
      'material': 'Polyester',
      'style_vibe': 'Professional',
      'wearCount': 3,
      'rating': 4.2,
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1b84df365-1765986465499.png',
      'semanticLabel': 'Gray formal dress pants',
    },
    {
      'id': 'item_005',
      'name': 'Black Leather Shoes',
      'category': 'Shoes',
      'color': 'Black',
      'material': 'Leather',
      'style_vibe': 'Professional',
      'wearCount': 6,
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1650741562741-19e5b5f7ed09',
      'semanticLabel': 'Black leather dress shoes',
    },
  ];

  // Mock suggestion data with outfit combinations
  final List<Map<String, dynamic>> _suggestions = [
    {
      "id": "sug_001",
      "outfitImage":
          "https://images.unsplash.com/photo-1579014133304-7004d757f5d2",
      "semanticLabel":
          "Casual outfit combination with white t-shirt and blue jeans laid flat on wooden surface",
      "confidence": 95,
      "reasoning":
          "Based on your love for this top - you've rated it 5 stars every time",
      "occasion": "casual",
      "items": [
        {
          "name": "White Cotton Tee",
          "lastWorn": "3 days ago",
          "image":
              "https://images.unsplash.com/photo-1722310752951-4d459d28c678",
          "semanticLabel":
              "White cotton t-shirt on hanger against white background",
        },
        {
          "name": "Classic Blue Jeans",
          "lastWorn": "1 week ago",
          "image":
              "https://images.unsplash.com/photo-1637069585336-827b298fe84a",
          "semanticLabel": "Blue denim jeans folded on white surface",
        },
      ],
      "stylingTips":
          "Roll up the sleeves for a more relaxed look. Add white sneakers to complete the outfit.",
      "weatherAppropriate": true,
    },
    {
      "id": "sug_002",
      "outfitImage":
          "https://img.rocket.new/generatedImages/rocket_gen_img_11c7650d6-1764746226516.png",
      "semanticLabel":
          "Professional work outfit with blazer and dress pants on mannequin",
      "confidence": 88,
      "reasoning":
          "You haven't worn these together yet - perfect for today's meeting",
      "occasion": "work",
      "items": [
        {
          "name": "Navy Blazer",
          "lastWorn": "2 weeks ago",
          "image":
              "https://images.unsplash.com/photo-1681510322233-9e44fb04b6f6",
          "semanticLabel": "Navy blue blazer hanging on wooden hanger",
        },
        {
          "name": "Gray Dress Pants",
          "lastWorn": "5 days ago",
          "image":
              "https://img.rocket.new/generatedImages/rocket_gen_img_1b84df365-1765986465499.png",
          "semanticLabel": "Gray formal dress pants folded neatly",
        },
      ],
      "stylingTips":
          "Pair with a crisp white shirt and brown leather shoes for a polished professional look.",
      "weatherAppropriate": true,
    },
    {
      "id": "sug_003",
      "outfitImage":
          "https://img.rocket.new/generatedImages/rocket_gen_img_16a3ebadc-1767385375179.png",
      "semanticLabel":
          "Elegant evening dress outfit with accessories on display",
      "confidence": 82,
      "reasoning":
          "This combination matches your style preferences and the weather forecast",
      "occasion": "special",
      "items": [
        {
          "name": "Black Midi Dress",
          "lastWorn": "3 weeks ago",
          "image":
              "https://img.rocket.new/generatedImages/rocket_gen_img_12f476cc8-1764658184304.png",
          "semanticLabel": "Black midi dress on hanger with elegant draping",
        },
        {
          "name": "Statement Necklace",
          "lastWorn": "1 month ago",
          "image":
              "https://images.unsplash.com/photo-1669814697763-85415492124d",
          "semanticLabel":
              "Gold statement necklace with geometric design on white background",
        },
      ],
      "stylingTips":
          "Add strappy heels and a clutch for a complete evening look. Keep makeup minimal to let the outfit shine.",
      "weatherAppropriate": false,
    },
  ];

  // Mock neglected items data
  final List<Map<String, dynamic>> _neglectedItems = [
    {
      "name": "Floral Summer Dress",
      "lastWorn": "45 days ago",
      "image": "https://images.unsplash.com/photo-1581356223915-ad2bf8fab009",
      "semanticLabel":
          "Colorful floral print summer dress hanging on white wall",
      "wearCount": 2,
    },
    {
      "name": "Denim Jacket",
      "lastWorn": "38 days ago",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_14e979a36-1764650961060.png",
      "semanticLabel": "Light blue denim jacket laid flat on wooden surface",
      "wearCount": 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateAISuggestions();
  }

  /// Generate AI-powered outfit suggestions
  Future<void> _generateAISuggestions() async {
    if (_wardrobeItems.isEmpty) return;

    setState(() {
      _isGeneratingAI = true;
    });

    try {
      final suggestions = await _stylistEngine.generateSuggestions(
        wardrobeItems: _wardrobeItems,
        occasion: _selectedOccasion == 'all' ? 'casual' : _selectedOccasion,
        weatherData: _weatherData,
        maxSuggestions: 5,
      );

      setState(() {
        _aiGeneratedSuggestions = suggestions;
        _isGeneratingAI = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingAI = false;
      });
    }
  }

  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    // Check if user has sufficient data for suggestions
    final bool hasSufficientData = _suggestions.isNotEmpty;

    return Column(
      children: [
        // Custom AppBar content
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.smartSuggestionsTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshSuggestions,
                      icon: _isRefreshing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : CustomIconWidget(
                              iconName: 'refresh',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                      tooltip: localizations.refreshSuggestions,
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                // Weather context
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: _weatherData["icon"] as String,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_weatherData["temperature"]}°F - ${_weatherData["condition"]}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _weatherData["location"] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main content
        Expanded(
          child: hasSufficientData
              ? _buildSuggestionsContent(theme)
              : EmptyStateWidget(
                  onNavigateToLog: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/outfit-capture-flow');
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsContent(ThemeData theme) {
    // Combine AI-generated and mock suggestions
    final allSuggestions = [..._aiGeneratedSuggestions, ..._suggestions];

    final filteredSuggestions = _selectedOccasion == 'all'
        ? allSuggestions
        : allSuggestions
              .where((s) => (s["occasion"] as String) == _selectedOccasion)
              .toList();

    if (_isGeneratingAI && filteredSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              localizations.analyzingWardrobe,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // AI Chat Bubble Widget - ALWAYS VISIBLE when there are suggestions
        if (_showAIBubble && filteredSuggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: AiSuggestionBubbleWidget(
              suggestions: _generateAIBubbleMessage(
                filteredSuggestions.length,
                localizations,
              ),
              onDismiss: () {
                setState(() => _showAIBubble = false);
              },
            ),
          ),

        // AI Status Banner
        if (_aiGeneratedSuggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      localizations.getAiBannerText(_aiGeneratedSuggestions.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Filter chips
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.filterByOccasion,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChipWidget(
                        label: localizations.filterAll,
                        isSelected: _selectedOccasion == 'all',
                        onTap: () => _updateFilter('all'),
                      ),
                      SizedBox(width: 2.w),
                      FilterChipWidget(
                        label: localizations.filterWork,
                        isSelected: _selectedOccasion == 'work',
                        onTap: () => _updateFilter('work'),
                      ),
                      SizedBox(width: 2.w),
                      FilterChipWidget(
                        label: localizations.filterCasual,
                        isSelected: _selectedOccasion == 'casual',
                        onTap: () => _updateFilter('casual'),
                      ),
                      SizedBox(width: 2.w),
                      FilterChipWidget(
                        label: localizations.filterSpecial,
                        isSelected: _selectedOccasion == 'special',
                        onTap: () => _updateFilter('special'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Suggestion cards
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final suggestion = filteredSuggestions[index];
              final isAIGenerated = suggestion['aiGenerated'] == true;

              return SuggestionCardWidget(
                suggestion: suggestion,
                isSaved: _savedSuggestions.contains(suggestion["id"] as String),
                isAIGenerated: isAIGenerated,
                onWearThis: () => _handleWearThis(suggestion),
                onSaveForLater: () => _handleSaveForLater(suggestion),
                onDismiss: () => _handleDismiss(suggestion),
                onTap: () => _showSuggestionDetail(suggestion),
              );
            }, childCount: filteredSuggestions.length),
          ),
        ),

        // Neglected items section
        _neglectedItems.isNotEmpty
            ? SliverToBoxAdapter(
                child: NeglectedItemsWidget(
                  items: _neglectedItems,
                  onItemTap: (item) => _handleNeglectedItemTap(item),
                ),
              )
            : const SliverToBoxAdapter(child: SizedBox.shrink()),

        // Bottom padding
        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
      ],
    );
  }

  String _generateAIBubbleMessage(
    int totalSuggestions,
    AppLocalizations localizations,
  ) {
    if (_aiGeneratedSuggestions.isEmpty) {
      return localizations.getAiBubbleInitialMessage(totalSuggestions);
    }

    final topSuggestion = _aiGeneratedSuggestions.first;
    final int confidence = topSuggestion['confidence'] ?? 90;

    return localizations.getAiBubbleFoundMessage(
      _aiGeneratedSuggestions.length,
      confidence,
    );
  }

  void _updateFilter(String occasion) {
    setState(() {
      _selectedOccasion = occasion;
    });

    // Regenerate AI suggestions for new occasion
    _generateAISuggestions();
  }

  Future<void> _refreshSuggestions() async {
    setState(() {
      _isRefreshing = true;
    });

    // Regenerate AI suggestions
    await _generateAISuggestions();

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.refreshSuggestions,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _handleWearThis(Map<String, dynamic> suggestion) {
    // Navigate to daily log with pre-selected outfit
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/outfit-capture-flow');

    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.outfitAddedToLog),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleSaveForLater(Map<String, dynamic> suggestion) {
    setState(() {
      final id = suggestion["id"] as String;
      if (_savedSuggestions.contains(id)) {
        _savedSuggestions.remove(id);
      } else {
        _savedSuggestions.add(id);
      }
    });

    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _savedSuggestions.contains(suggestion["id"] as String)
              ? localizations.savedForLater
              : localizations.removedFromSaved,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleDismiss(Map<String, dynamic> suggestion) {
    setState(() {
      _suggestions.remove(suggestion);
    });

    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.suggestionDismissed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: localizations.undo,
          onPressed: () {
            setState(() {
              _suggestions.add(suggestion);
            });
          },
        ),
      ),
    );
  }

  void _showSuggestionDetail(Map<String, dynamic> suggestion) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outfit image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomImageWidget(
                        imageUrl: suggestion["outfitImage"] as String,
                        width: double.infinity,
                        height: 40.h,
                        fit: BoxFit.cover,
                        semanticLabel: suggestion["semanticLabel"] as String,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Confidence and reasoning
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'verified',
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${suggestion["confidence"]}% match',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      suggestion["reasoning"] as String,
                      style: theme.textTheme.bodyLarge,
                    ),

                    SizedBox(height: 3.h),

                    // Individual items
                    Text(
                      localizations.itemsInThisOutfit,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    ...(suggestion["items"] as List).map((item) {
                      final itemMap = item as Map<String, dynamic>;
                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomImageWidget(
                                imageUrl: itemMap["image"] as String,
                                width: 15.w,
                                height: 15.w,
                                fit: BoxFit.cover,
                                semanticLabel:
                                    itemMap["semanticLabel"] as String,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemMap["name"] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    '${localizations.lastWornLabel}: ${itemMap["lastWorn"]}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    SizedBox(height: 2.h),

                    // Styling tips
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.tertiary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomIconWidget(
                            iconName: 'lightbulb',
                            color: theme.colorScheme.tertiary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Styling Tips',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  suggestion["stylingTips"] as String,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleWearThis(suggestion);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            ),
                            child: const Text('Wear This Today'),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleSaveForLater(suggestion);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            ),
                            child: const Text('Save for Later'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNeglectedItemTap(Map<String, dynamic> item) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/wardrobe-management');
  }
}
