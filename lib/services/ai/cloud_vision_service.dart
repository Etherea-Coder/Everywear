import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloud Vision Service - Tier 2 AI
/// Free cloud-based AI analysis via Hugging Face API
/// Used when user hasn't downloaded on-device model
class CloudVisionService {
  static const String cloudEndpoint = String.fromEnvironment(
    'HUGGING_FACE_API_URL',
    defaultValue:
        'https://api-inference.huggingface.co/models/vikhyatk/moondream2',
  );
  static const String apiKey = String.fromEnvironment('HUGGING_FACE_API_KEY');
  static const Duration timeout = Duration(seconds: 10);

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  /// Analyze clothing photo using cloud API
  Future<Map<String, dynamic>?> analyzePhoto(String imagePath) async {
    try {
      // Check connectivity
      if (!await isOnline()) {
        if (kDebugMode) print('Cloud AI: No internet connection');
        return null;
      }

      // Read image bytes
      final imageBytes = kIsWeb
          ? await _readWebImage(imagePath)
          : await File(imagePath).readAsBytes();

      if (imageBytes == null) return null;

      // Prepare request
      final request = http.MultipartRequest('POST', Uri.parse(cloudEndpoint));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'clothing.jpg',
        ),
      );

      if (apiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $apiKey';
      }

      // Send request with timeout
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseCloudResponse(data);
      } else {
        if (kDebugMode) {
          print('Cloud AI: API error ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Cloud AI failed: $e');
      return null; // Always fail gracefully
    }
  }

  Future<List<int>?> _readWebImage(String imagePath) async {
    try {
      // For web, imagePath might be a blob URL or data URL
      return null; // Web implementation would use different approach
    } catch (e) {
      return null;
    }
  }

  /// Parse cloud API response into standard format
  Map<String, dynamic> _parseCloudResponse(dynamic data) {
    // Parse Hugging Face API response
    // This is a simplified parser - adjust based on actual API response
    try {
      final description = data['generated_text'] ?? data['description'] ?? '';
      return _extractClothingInfo(description);
    } catch (e) {
      return _getDefaultAnalysis();
    }
  }

  /// Extract clothing information from AI description
  Map<String, dynamic> _extractClothingInfo(String description) {
    final lowerDesc = description.toLowerCase();

    // Category detection
    String category = 'Tops';
    if (lowerDesc.contains('dress')) {
      category = 'Dresses';
    } else if (lowerDesc.contains('pant') ||
        lowerDesc.contains('jean') ||
        lowerDesc.contains('trouser')) {
      category = 'Bottoms';
    } else if (lowerDesc.contains('jacket') ||
        lowerDesc.contains('coat') ||
        lowerDesc.contains('sweater')) {
      category = 'Outerwear';
    } else if (lowerDesc.contains('shoe') ||
        lowerDesc.contains('sneaker') ||
        lowerDesc.contains('boot')) {
      category = 'Shoes';
    } else if (lowerDesc.contains('bag') ||
        lowerDesc.contains('hat') ||
        lowerDesc.contains('scarf')) {
      category = 'Accessories';
    }

    // Color detection
    String color = 'Unknown';
    final colors = [
      'black',
      'white',
      'blue',
      'red',
      'green',
      'yellow',
      'pink',
      'gray',
      'brown',
      'beige',
    ];
    for (final c in colors) {
      if (lowerDesc.contains(c)) {
        color = c[0].toUpperCase() + c.substring(1);
        break;
      }
    }

    // Material detection
    String material = 'Cotton';
    if (lowerDesc.contains('denim')) {
      material = 'Denim';
    } else if (lowerDesc.contains('leather')) {
      material = 'Leather';
    } else if (lowerDesc.contains('wool')) {
      material = 'Wool';
    } else if (lowerDesc.contains('silk')) {
      material = 'Silk';
    } else if (lowerDesc.contains('polyester')) {
      material = 'Polyester';
    }

    return {
      'category': category,
      'confidence': 0.70, // Cloud AI moderate confidence
      'color': color,
      'material': material,
      'style_vibe': 'Casual',
      'tags': [category.toLowerCase(), color.toLowerCase(), 'cloud-ai'],
      'source': 'cloud',
    };
  }

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      'category': 'Tops',
      'confidence': 0.50,
      'color': 'Unknown',
      'material': 'Cotton',
      'style_vibe': 'Casual',
      'tags': ['tops', 'cloud-ai'],
      'source': 'cloud',
    };
  }
}
