import 'dart:math';
import 'package:flutter/foundation.dart';

/// Carries all user-facing strings from the calling widget into the engine.
class StylistStrings {
  final String? userName;             // ← NEW
  final String includesFavorite;      // e.g. 'Includes your favorite %s'
  final String perfectTimeToWear;     // e.g. 'Perfect time to wear your %s'
  final String lightAndBreathable;    // e.g. 'Light and breathable for %s°C'
  final String warmAndCozy;           // e.g. 'Warm and cozy for %s°C'
  final String professionalAndPolished;
  final String comfortableAndRelaxed;
  final String aiCurated;
  final String layerOuterwear;
  final String addBelt;
  final String considerAccessories;
  final String ensureShoes;
  final String experimentAccessories;
  final String wearWithConfidence;

  const StylistStrings({
    this.userName,                    // ← NEW
    required this.includesFavorite,
    required this.perfectTimeToWear,
    required this.lightAndBreathable,
    required this.warmAndCozy,
    required this.professionalAndPolished,
    required this.comfortableAndRelaxed,
    required this.aiCurated,
    required this.layerOuterwear,
    required this.addBelt,
    required this.considerAccessories,
    required this.ensureShoes,
    required this.experimentAccessories,
    required this.wearWithConfidence,
  });
}

class StylistEngineService {
  static final StylistEngineService _instance =
      StylistEngineService._internal();
  factory StylistEngineService() => _instance;
  StylistEngineService._internal();

  final Random _random = Random();

  static const Map<String, Map<String, dynamic>> _occasionRules = {
    'work': {
      'preferred_categories': ['Tops', 'Bottoms', 'Outerwear', 'Shoes'],
      'preferred_colors': ['Black', 'Gray', 'Blue', 'White', 'Brown'],
      'preferred_vibes': ['Professional', 'Elegant', 'Versatile'],
      'avoid_categories': ['Activewear', 'Sleepwear'],
      'formality': 0.8,
    },
    'casual': {
      'preferred_categories': ['Tops', 'Bottoms', 'Shoes', 'Accessories'],
      'preferred_colors': ['Blue', 'White', 'Gray', 'Green', 'Beige'],
      'preferred_vibes': ['Casual', 'Versatile', 'Sporty'],
      'avoid_categories': ['Sleepwear'],
      'formality': 0.3,
    },
    'special': {
      'preferred_categories': ['Dresses', 'Outerwear', 'Shoes', 'Accessories'],
      'preferred_colors': ['Black', 'Red', 'Blue', 'Pink', 'White'],
      'preferred_vibes': ['Elegant', 'Versatile'],
      'avoid_categories': ['Activewear', 'Sleepwear'],
      'formality': 0.9,
    },
    'athletic': {
      'preferred_categories': ['Activewear', 'Shoes', 'Tops', 'Bottoms'],
      'preferred_colors': ['Black', 'Gray', 'Blue', 'Green', 'Red'],
      'preferred_vibes': ['Sporty', 'Casual'],
      'avoid_categories': ['Dresses', 'Outerwear'],
      'formality': 0.1,
    },
  };

  static const Map<String, Map<String, dynamic>> _weatherRules = {
    'hot': {
      'temperature_range': [24, 50],
      'preferred_materials': ['Cotton', 'Linen'],
      'preferred_categories': ['Tops', 'Dresses', 'Shoes'],
      'avoid_categories': ['Outerwear'],
      'layer_count': 1,
    },
    'warm': {
      'temperature_range': [18, 24],
      'preferred_materials': ['Cotton', 'Polyester'],
      'preferred_categories': ['Tops', 'Bottoms', 'Dresses'],
      'avoid_categories': [],
      'layer_count': 2,
    },
    'cool': {
      'temperature_range': [10, 18],
      'preferred_materials': ['Cotton', 'Denim', 'Polyester'],
      'preferred_categories': ['Tops', 'Bottoms', 'Outerwear'],
      'avoid_categories': ['Dresses'],
      'layer_count': 2,
    },
    'cold': {
      'temperature_range': [-20, 10],
      'preferred_materials': ['Wool', 'Denim'],
      'preferred_categories': ['Outerwear', 'Tops', 'Bottoms'],
      'avoid_categories': ['Dresses'],
      'layer_count': 3,
    },
  };

  Future<List<Map<String, dynamic>>> generateSuggestions({
    required List<Map<String, dynamic>> wardrobeItems,
    required String occasion,
    required Map<String, dynamic> weatherData,
    required StylistStrings strings,   // ← NEW
    int maxSuggestions = 5,
  }) async {
    try {
      if (wardrobeItems.isEmpty) return [];

      final occasionKey = occasion.toLowerCase();
      final occasionRule =
          _occasionRules[occasionKey] ?? _occasionRules['casual']!;
      final weatherRule = _getWeatherRule(weatherData['temperature'] as int);

      final suitableItems =
          _filterSuitableItems(wardrobeItems, occasionRule, weatherRule);

      if (suitableItems.isEmpty) return [];

      final suggestions = <Map<String, dynamic>>[];
      for (int i = 0; i < maxSuggestions && i < suitableItems.length; i++) {
        final outfit = await _generateOutfit(
          suitableItems, occasionRule, weatherRule, weatherData, strings,
        );
        if (outfit != null) suggestions.add(outfit);
      }
      return suggestions;
    } catch (e) {
      if (kDebugMode) debugPrint('Error generating suggestions: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _filterSuitableItems(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherRule,
  ) {
    final avoidCategories = [
      ...(occasionRule['avoid_categories'] as List<String>),
      ...(weatherRule['avoid_categories'] as List<String>),
    ];
    return items.where((item) {
      final category = item['category'] as String?;
      return category != null && !avoidCategories.contains(category);
    }).toList();
  }

  Future<Map<String, dynamic>?> _generateOutfit(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherRule,
    Map<String, dynamic> weatherData,
    StylistStrings strings,            // ← NEW
  ) async {
    try {
      final layerCount = weatherRule['layer_count'] as int;
      final outfitItems = <Map<String, dynamic>>[];
      final preferredCategories =
          occasionRule['preferred_categories'] as List<String>;
      final shuffledItems = List<Map<String, dynamic>>.from(items)
        ..shuffle(_random);

      for (final category in preferredCategories) {
        if (outfitItems.length >= layerCount + 1) break;
        final categoryItem = shuffledItems.firstWhere(
          (item) =>
              item['category'] == category && !outfitItems.contains(item),
          orElse: () => {},
        );
        if (categoryItem.isNotEmpty) outfitItems.add(categoryItem);
      }

      if (outfitItems.length < 2) return null;

      final confidence =
          _calculateConfidence(outfitItems, occasionRule, weatherRule);
      final reasoning =
          _generateReasoning(outfitItems, occasionRule, weatherData, strings);
      final stylingTips = _generateStylingTips(outfitItems, occasionRule, strings);

      return {
        'id': 'ai_sug_${DateTime.now().millisecondsSinceEpoch}',
        'items': outfitItems,
        'confidence': confidence,
        'reasoning': reasoning,
        'occasion': occasionRule.keys.first,
        'stylingTips': stylingTips,
        'weatherAppropriate': true,
        'aiGenerated': true,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error generating outfit: $e');
      return null;
    }
  }

  double _calculateConfidence(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherRule,
  ) {
    double score = 0.7;

    final preferredColors = occasionRule['preferred_colors'] as List<String>;
    final colorMatches = items.where((item) {
      final color = item['color'] as String?;
      return color != null && preferredColors.contains(color);
    }).length;
    score += (colorMatches / items.length) * 0.15;

    final preferredVibes = occasionRule['preferred_vibes'] as List<String>;
    final vibeMatches = items.where((item) {
      final vibe = item['style_vibe'] as String?;
      return vibe != null && preferredVibes.contains(vibe);
    }).length;
    score += (vibeMatches / items.length) * 0.1;

    final preferredMaterials =
        weatherRule['preferred_materials'] as List<String>;
    final materialMatches = items.where((item) {
      final material = item['material'] as String?;
      return material != null && preferredMaterials.contains(material);
    }).length;
    score += (materialMatches / items.length) * 0.05;

    // Rating-based boost: items from highly-rated outfits increase confidence
    final ratedItems = items.where((item) {
      final avgRating = item['avg_rating'] as double?;
      return avgRating != null && avgRating >= 4.0;
    }).length;
    score += (ratedItems / items.length) * 0.1;

    return (score * 100).clamp(65, 98).toDouble();
  }

  String _generateReasoning(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherData,
    StylistStrings strings,            // ← NEW
  ) {
    final reasons = <String>[];
    final personalizedCurated = strings.userName != null 
        ? "Curated for ${strings.userName}" 
        : strings.aiCurated;

    final highRatedItems = items.where((item) {
      final rating = item['rating'] as double?;
      return rating != null && rating >= 4.5;
    });
    if (highRatedItems.isNotEmpty) {
      var favString = strings.includesFavorite;
      if (strings.userName != null && favString.contains('your')) {
        favString = favString.replaceFirst('your', "${strings.userName}'s");
      }
      reasons.add(
        favString.replaceFirst('%s', highRatedItems.first['name'] as String? ?? ''),
      );
    }

    // Items with high average outfit ratings are proven favourites
    final topRatedByOutfit = items.where((item) {
      final avgRating = item['avg_rating'] as double?;
      return avgRating != null && avgRating >= 4.0;
    });
    if (topRatedByOutfit.isNotEmpty && highRatedItems.isEmpty) {
      final itemName = topRatedByOutfit.first['name'] as String? ?? '';
      final avgRating = topRatedByOutfit.first['avg_rating'] as double;
      reasons.add(
        'Your $itemName appears in outfits you rated ${avgRating.toStringAsFixed(1)}/5 on average',
      );
    }

    final neglectedItems = items.where((item) {
      final wearCount = item['wearCount'] as int? ?? 0;
      return wearCount < 3;
    });
    if (neglectedItems.isNotEmpty) {
      reasons.add(
        strings.perfectTimeToWear.replaceFirst('%s', neglectedItems.first['name'] as String? ?? ''),
      );
    }

    final temp = weatherData['temperature'] as int;
    if (temp >= 24) {
      reasons.add(strings.lightAndBreathable.replaceFirst('%s', '$temp'));
    } else if (temp <= 10) {
      reasons.add(strings.warmAndCozy.replaceFirst('%s', '$temp'));
    }

    final formality = occasionRule['formality'] as double;
    if (formality > 0.7) {
      reasons.add(strings.professionalAndPolished);
    } else if (formality < 0.4) {
      reasons.add(strings.comfortableAndRelaxed);
    }

    return reasons.isNotEmpty ? reasons.first : personalizedCurated;
  }

  String _generateStylingTips(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    StylistStrings strings,            // ← NEW
  ) {
    final tips = <String>[];

    final hasOuterwear = items.any((item) => item['category'] == 'Outerwear');
    final hasDress = items.any((item) => item['category'] == 'Dresses');
    final hasAccessories =
        items.any((item) => item['category'] == 'Accessories');

    if (hasOuterwear) tips.add(strings.layerOuterwear);
    if (hasDress) tips.add(strings.addBelt);
    if (!hasAccessories) tips.add(strings.considerAccessories);

    final formality = occasionRule['formality'] as double;
    if (formality > 0.7) {
      tips.add(strings.ensureShoes);
    } else {
      tips.add(strings.experimentAccessories);
    }

    return tips.isNotEmpty
        ? tips[_random.nextInt(tips.length)]
        : strings.wearWithConfidence;
  }

  Map<String, dynamic> _getWeatherRule(int temperature) {
    if (temperature >= 24) return _weatherRules['hot']!;
    if (temperature >= 18) return _weatherRules['warm']!;
    if (temperature >= 10) return _weatherRules['cool']!;
    return _weatherRules['cold']!;
  }
}
