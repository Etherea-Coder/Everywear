import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai_request_id.dart';
import '../ai_locale_context.dart';
import './cloud_vision_service.dart';

/// Vision Engine Service Interface
/// Two-Tier AI System:
/// Tier 1: Cloud AI via Gemini (free, when online)
/// Tier 2: Manual entry (always available as fallback)
abstract class VisionEngineService {
  static VisionEngineService? _instance;

  factory VisionEngineService() {
    _instance ??= kIsWeb
        ? VisionEngineServiceWeb()
        : VisionEngineServiceMobile();
    return _instance!;
  }

  Future<Map<String, dynamic>> analyzeClothing(
    String imagePath, {
    required Locale locale,
  });
  Future<String> getAITier(); // Returns: 'cloud' or 'manual'
  void dispose();
}

/// Web implementation (heuristic fallback - no Gemini access on web)
class VisionEngineServiceWeb implements VisionEngineService {
  final CloudVisionService _cloudService = CloudVisionService();

  @override
  Future<Map<String, dynamic>> analyzeClothing(
    String imagePath, {
    required Locale locale,
  }) async {
    // Web has no Gemini access, use heuristic fallback
    return _getHeuristicAnalysis();
  }

  Map<String, dynamic> _getHeuristicAnalysis() {
    return {
      'category': 'Tops',
      'confidence': 0.60,
      'color': 'Blue',
      'material': 'Cotton',
      'style_vibe': 'Casual',
      'tags': ['tops', 'blue', 'cotton'],
      'source': 'heuristic',
    };
  }

  @override
  Future<String> getAITier() async {
    if (await _cloudService.isOnline()) return 'cloud';
    return 'manual';
  }

  @override
  void dispose() {}
}

/// Mobile implementation with two-tier system
class VisionEngineServiceMobile implements VisionEngineService {
  final CloudVisionService _cloudService = CloudVisionService();

  @override
  Future<Map<String, dynamic>> analyzeClothing(
    String imagePath, {
    required Locale locale,
  }) async {
    final geminiResult = await _analyzeWithGemini(imagePath, locale: locale);
    if (geminiResult != null) {
      return geminiResult;
    }

    throw StateError(
      'AI clothing analysis is unavailable. Enter item details manually.',
    );
  }

  Future<Map<String, dynamic>?> _analyzeWithGemini(
    String imagePath, {
    required Locale locale,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length > 3_000_000) return null;
      final base64Image = base64Encode(bytes);

      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'analyze-clothing',
        body: {
          'imageBase64': base64Image,
          'requestId': newAiRequestId(),
          ...AiLocaleContext.proseResponse(locale),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return {
          'category': response.data['category'] ?? 'Tops',
          'confidence': (response.data['confidence'] ?? 0.8).toDouble(),
          'color': response.data['color'] ?? 'Unknown',
          'material': response.data['material'] ?? 'Cotton',
          'style_vibe': response.data['style_vibe'] ?? 'Casual',
          'tags': [
            response.data['category']?.toLowerCase() ?? 'tops',
            'gemini-ai',
          ],
          'source': 'gemini',
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini analysis failed: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<String> getAITier() async {
    if (await _cloudService.isOnline()) return 'cloud';
    return 'manual';
  }

  @override
  void dispose() {}
}
