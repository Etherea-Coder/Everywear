import 'dart:math';
import 'package:flutter/foundation.dart';

/// Stylist Engine Service for AI-powered outfit recommendations
/// Analyzes wardrobe items and generates contextual outfit suggestions
class StylistEngineService {
  static final StylistEngineService _instance =
      StylistEngineService._internal();
  factory StylistEngineService() => _instance;
  StylistEngineService._internal();

  final Random _random = Random();

  // Occasion-based styling rules
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

  // Weather-based recommendations
  static const Map<String, Map<String, dynamic>> _weatherRules = {
    'hot': {
      'temperature_range': [75, 120],
      'preferred_materials': ['Cotton', 'Linen'],
      'preferred_categories': ['Tops', 'Dresses', 'Shoes'],
      'avoid_categories': ['Outerwear'],
      'layer_count': 1,
    },
    'warm': {
      'temperature_range': [65, 75],
      'preferred_materials': ['Cotton', 'Polyester'],
      'preferred_categories': ['Tops', 'Bottoms', 'Dresses'],
      'avoid_categories': [],
      'layer_count': 2,
    },
    'cool': {
      'temperature_range': [50, 65],
      'preferred_materials': ['Cotton', 'Denim', 'Polyester'],
      'preferred_categories': ['Tops', 'Bottoms', 'Outerwear'],
      'avoid_categories': ['Dresses'],
      'layer_count': 2,
    },
    'cold': {
      'temperature_range': [0, 50],
      'preferred_materials': ['Wool', 'Denim'],
      'preferred_categories': ['Outerwear', 'Tops', 'Bottoms'],
      'avoid_categories': ['Dresses'],
      'layer_count': 3,
    },
  };

  /// Generate smart outfit suggestions
  Future<List<Map<String, dynamic>>> generateSuggestions({
    required List<Map<String, dynamic>> wardrobeItems,
    required String occasion,
    required Map<String, dynamic> weatherData,
    int maxSuggestions = 5,
  }) async {
    try {
      if (wardrobeItems.isEmpty) {
        return [];
      }

      // Get occasion and weather rules
      final occasionKey = occasion.toLowerCase();
      final occasionRule =
          _occasionRules[occasionKey] ?? _occasionRules['casual']!;
      final weatherRule = _getWeatherRule(weatherData['temperature'] as int);

      // Filter items based on occasion and weather
      final suitableItems = _filterSuitableItems(
        wardrobeItems,
        occasionRule,
        weatherRule,
      );

      if (suitableItems.isEmpty) {
        return [];
      }

      // Generate outfit combinations
      final suggestions = <Map<String, dynamic>>[];

      for (int i = 0; i < maxSuggestions && i < suitableItems.length; i++) {
        final outfit = await _generateOutfit(
          suitableItems,
          occasionRule,
          weatherRule,
          weatherData,
        );

        if (outfit != null) {
          suggestions.add(outfit);
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
      return [];
    }
  }

  /// Filter items suitable for occasion and weather
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

  /// Generate a single outfit combination
  Future<Map<String, dynamic>?> _generateOutfit(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherRule,
    Map<String, dynamic> weatherData,
  ) async {
    try {
      // Select items for outfit (2-4 items depending on weather)
      final layerCount = weatherRule['layer_count'] as int;
      final outfitItems = <Map<String, dynamic>>[];

      // Try to include diverse categories
      final preferredCategories =
          occasionRule['preferred_categories'] as List<String>;
      final shuffledItems = List<Map<String, dynamic>>.from(items)
        ..shuffle(_random);

      for (final category in preferredCategories) {
        if (outfitItems.length >= layerCount + 1) break;

        final categoryItem = shuffledItems.firstWhere(
          (item) => item['category'] == category && !outfitItems.contains(item),
          orElse: () => {},
        );

        if (categoryItem.isNotEmpty) {
          outfitItems.add(categoryItem);
        }
      }

      if (outfitItems.length < 2) {
        return null;
      }

      // Calculate confidence score
      final confidence = _calculateConfidence(
        outfitItems,
        occasionRule,
        weatherRule,
      );

      // Generate reasoning
      final reasoning = _generateReasoning(
        outfitItems,
        occasionRule,
        weatherData,
      );

      // Generate styling tips
      final stylingTips = _generateStylingTips(outfitItems, occasionRule);

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
      debugPrint('Error generating outfit: $e');
      return null;
    }
  }

  /// Calculate confidence score for outfit
  double _calculateConfidence(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherRule,
  ) {
    double score = 0.7; // Base confidence

    // Boost for preferred colors
    final preferredColors = occasionRule['preferred_colors'] as List<String>;
    final colorMatches = items.where((item) {
      final color = item['color'] as String?;
      return color != null && preferredColors.contains(color);
    }).length;

    score += (colorMatches / items.length) * 0.15;

    // Boost for preferred vibes
    final preferredVibes = occasionRule['preferred_vibes'] as List<String>;
    final vibeMatches = items.where((item) {
      final vibe = item['style_vibe'] as String?;
      return vibe != null && preferredVibes.contains(vibe);
    }).length;

    score += (vibeMatches / items.length) * 0.1;

    // Boost for weather-appropriate materials
    final preferredMaterials =
        weatherRule['preferred_materials'] as List<String>;
    final materialMatches = items.where((item) {
      final material = item['material'] as String?;
      return material != null && preferredMaterials.contains(material);
    }).length;

    score += (materialMatches / items.length) * 0.05;

    return (score * 100).clamp(65, 98).toDouble();
  }

  /// Generate reasoning for outfit suggestion
  String _generateReasoning(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
    Map<String, dynamic> weatherData,
  ) {
    final reasons = <String>[];

    // Check for highly rated items
    final highRatedItems = items.where((item) {
      final rating = item['rating'] as double?;
      return rating != null && rating >= 4.5;
    });

    if (highRatedItems.isNotEmpty) {
      reasons.add('Includes your favorite ${highRatedItems.first['name']}');
    }

    // Check for underutilized items
    final neglectedItems = items.where((item) {
      final wearCount = item['wearCount'] as int? ?? 0;
      return wearCount < 3;
    });

    if (neglectedItems.isNotEmpty) {
      reasons.add('Perfect time to wear your ${neglectedItems.first['name']}');
    }

    // Weather consideration
    final temp = weatherData['temperature'] as int;
    if (temp > 75) {
      reasons.add('Light and breathable for ${temp}°F weather');
    } else if (temp < 50) {
      reasons.add('Warm and cozy for ${temp}°F weather');
    }

    // Occasion match
    final formality = occasionRule['formality'] as double;
    if (formality > 0.7) {
      reasons.add('Professional and polished for work');
    } else if (formality < 0.4) {
      reasons.add('Comfortable and relaxed for casual wear');
    }

    return reasons.isNotEmpty
        ? reasons.first
        : 'AI-curated combination based on your wardrobe';
  }

  /// Generate styling tips
  String _generateStylingTips(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> occasionRule,
  ) {
    final tips = <String>[];

    // Category-specific tips
    final hasOuterwear = items.any((item) => item['category'] == 'Outerwear');
    final hasDress = items.any((item) => item['category'] == 'Dresses');
    final hasAccessories = items.any(
      (item) => item['category'] == 'Accessories',
    );

    if (hasOuterwear) {
      tips.add('Layer your outerwear for easy temperature adjustment');
    }

    if (hasDress) {
      tips.add('Add a belt to define your waist and elevate the look');
    }

    if (!hasAccessories) {
      tips.add(
        'Consider adding a watch or simple jewelry to complete the outfit',
      );
    }

    // Occasion-specific tips
    final formality = occasionRule['formality'] as double;
    if (formality > 0.7) {
      tips.add('Ensure shoes are polished and accessories are minimal');
    } else {
      tips.add('Feel free to experiment with bold accessories');
    }

    return tips.isNotEmpty
        ? tips[_random.nextInt(tips.length)]
        : 'Wear with confidence and make it your own';
  }

  /// Get weather rule based on temperature
  Map<String, dynamic> _getWeatherRule(int temperature) {
    if (temperature >= 75) {
      return _weatherRules['hot']!;
    } else if (temperature >= 65) {
      return _weatherRules['warm']!;
    } else if (temperature >= 50) {
      return _weatherRules['cool']!;
    } else {
      return _weatherRules['cold']!;
    }
  }
}
