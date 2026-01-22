import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model Download Service - Tier 3 AI
/// Manages on-device AI model download, storage, and deletion
class ModelDownloadService {
  static const String modelUrl = String.fromEnvironment(
    'AI_MODEL_URL',
    defaultValue:
        'https://huggingface.co/vikhyatk/moondream2/resolve/main/moondream2-text-model-f16.gguf',
  );
  static const String modelFileName = 'moondream2_model.tflite';
  static const int modelSizeBytes = 400 * 1024 * 1024; // ~400MB

  /// Check if model is downloaded
  Future<bool> isModelDownloaded() async {
    try {
      if (kIsWeb) {
        // Web: Check localStorage
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('ai_model_downloaded') ?? false;
      } else {
        // Mobile: Check file exists
        final file = await _getModelFile();
        return await file.exists();
      }
    } catch (e) {
      return false;
    }
  }

  /// Get model file size in MB
  Future<double> getModelSize() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final size = prefs.getInt('ai_model_size') ?? 0;
        return size / (1024 * 1024);
      } else {
        final file = await _getModelFile();
        if (await file.exists()) {
          final bytes = await file.length();
          return bytes / (1024 * 1024);
        }
      }
    } catch (e) {
      return 0.0;
    }
    return 0.0;
  }

  /// Download AI model with progress callback
  Future<bool> downloadModel({
    Function(double progress)? onProgress,
    Function(String error)? onError,
  }) async {
    try {
      if (kIsWeb) {
        return await _downloadModelWeb(onProgress: onProgress);
      } else {
        return await _downloadModelMobile(onProgress: onProgress);
      }
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }

  /// Download model for mobile platforms
  Future<bool> _downloadModelMobile({
    Function(double progress)? onProgress,
  }) async {
    try {
      final file = await _getModelFile();

      // Check if already exists
      if (await file.exists()) {
        onProgress?.call(1.0);
        return true;
      }

      // Download with progress
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final total = response.contentLength ?? modelSizeBytes;
      var downloaded = 0;

      final sink = file.openWrite();
      await response.stream
          .map((chunk) {
            downloaded += chunk.length;
            final progress = downloaded / total;
            onProgress?.call(progress);
            return chunk;
          })
          .pipe(sink);

      await sink.close();
      client.close();

      // Save download status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_model_downloaded', true);
      await prefs.setInt('ai_model_size', downloaded);

      return true;
    } catch (e) {
      if (kDebugMode) print('Model download failed: $e');
      return false;
    }
  }

  /// Download model for web platform
  Future<bool> _downloadModelWeb({
    Function(double progress)? onProgress,
  }) async {
    try {
      // For web, we simulate download and mark as available
      // Actual web implementation would use IndexedDB or similar
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(i / 100);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_model_downloaded', true);
      await prefs.setInt('ai_model_size', modelSizeBytes);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete downloaded model
  Future<bool> deleteModel() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ai_model_downloaded');
        await prefs.remove('ai_model_size');
        return true;
      } else {
        final file = await _getModelFile();
        if (await file.exists()) {
          await file.delete();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ai_model_downloaded');
        await prefs.remove('ai_model_size');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Model deletion failed: $e');
      return false;
    }
  }

  /// Get model file path
  Future<File> _getModelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$modelFileName');
  }

  /// Get model file path as string
  Future<String> getModelPath() async {
    if (kIsWeb) return '';
    final file = await _getModelFile();
    return file.path;
  }
}
