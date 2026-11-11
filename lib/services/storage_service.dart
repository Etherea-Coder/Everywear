import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class StorageService {
  SupabaseClient get _client => SupabaseService.instance.client;
  static const String _bucket = 'wardrobe-images';

  static const _signedUrlLifetime = Duration(hours: 1);

  /// Describes how an image reference must be routed by presentation code.
  /// This pure classifier is also used by tests without initializing Supabase.
  static ImageReferenceRoute classifyImageReference(
    String value, {
    String? supabaseUrl,
  }) {
    if (_parseStorageReference(value, supabaseUrl: supabaseUrl) != null) {
      return ImageReferenceRoute.storage;
    }
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return ImageReferenceRoute.network;
    }
    if (value.startsWith('file://')) return ImageReferenceRoute.localFile;
    if (value.startsWith('assets/') || value.endsWith('.svg')) {
      return ImageReferenceRoute.asset;
    }
    return ImageReferenceRoute.asset;
  }

  static bool isStorageReference(String value, {String bucket = _bucket}) =>
      _parseStorageReference(value)?.$1 == bucket;

  /// Uploads and returns the stable owner scoped object path for persistence.
  Future<String?> uploadWardrobeImage(String localPath) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final file = File(localPath);
      if (!await file.exists()) return null;

      final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();

      await _client.storage
          .from(_bucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      if (kDebugMode)
        debugPrint('Uploaded wardrobe image reference: $fileName');
      return '$_bucket/$fileName';
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Converts a stable bucket/path reference (or legacy public URL) into a
  /// short lived authorized URL. The result must only be held in view state.
  Future<String?> resolveImageUrl(String reference) async {
    try {
      final parsed = _parseStorageReference(reference);
      if (parsed == null)
        return reference.startsWith('http') ? reference : null;
      final userId = _client.auth.currentUser?.id;
      if (userId == null || parsed.$2.split('/').first != userId) return null;
      return await _client.storage
          .from(parsed.$1)
          .createSignedUrl(parsed.$2, _signedUrlLifetime.inSeconds);
    } catch (error) {
      if (kDebugMode) debugPrint('Image URL resolution failed: $error');
      return null;
    }
  }

  static (String, String)? _parseStorageReference(
    String value, {
    String? supabaseUrl,
  }) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      for (final candidate in const ['wardrobe-images', 'avatars']) {
        final prefix = '$candidate/';
        if (value.startsWith(prefix) && value.length > prefix.length) {
          final path = value.substring(prefix.length);
          if (!path.startsWith('/') && !path.split('/').contains('..')) {
            return (candidate, path);
          }
        }
      }
      return null;
    }
    final configured = Uri.tryParse(
      supabaseUrl ?? SupabaseService.cleanSupabaseUrl,
    );
    if (configured == null ||
        uri.userInfo.isNotEmpty ||
        uri.scheme != 'https' ||
        uri.origin != configured.origin)
      return null;
    final segments = uri.pathSegments;
    if (segments.length < 5 ||
        segments[0] != 'storage' ||
        segments[1] != 'v1' ||
        segments[2] != 'object') {
      return null;
    }
    final route = segments[3];
    final bucketIndex = route == 'public' || route == 'sign' ? 4 : 3;
    if (bucketIndex >= segments.length) return null;
    final bucket = segments[bucketIndex];
    if (!const ['wardrobe-images', 'avatars'].contains(bucket) ||
        bucketIndex + 1 >= segments.length) {
      return null;
    }
    final path = Uri.decodeComponent(segments.skip(bucketIndex + 1).join('/'));
    if (path.split('/').contains('..')) return null;
    return (bucket, path);
  }

  /// Delete an image from Supabase Storage
  Future<bool> deleteWardrobeImage(String imageUrl) async {
    try {
      final parsed = _parseStorageReference(imageUrl);
      if (parsed == null || parsed.$1 != _bucket) return false;
      final userId = _client.auth.currentUser?.id;
      if (userId == null || parsed.$2.split('/').first != userId) return false;
      final filePath = parsed.$2;
      await _client.storage.from(_bucket).remove([filePath]);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting image: $e');
      return false;
    }
  }
}

enum ImageReferenceRoute { storage, network, localFile, asset }
