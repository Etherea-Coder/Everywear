import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class StorageService {
  SupabaseClient get _client => SupabaseService.instance.client;
  static const String _bucket = 'wardrobe-images';

  /// Upload a local image file to Supabase Storage
  /// Returns the public URL or null on failure
  Future<String?> uploadWardrobeImage(String localPath) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final file = File(localPath);
      if (!await file.exists()) return null;

      final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();

      await _client.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(fileName);
      debugPrint('Uploaded image: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Delete an image from Supabase Storage
  Future<bool> deleteWardrobeImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucket);
      if (bucketIndex == -1) return false;
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from(_bucket).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}
