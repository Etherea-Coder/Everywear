import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './serial_operation_queue.dart';
import './supabase_service.dart';

class StorageService {
  SupabaseClient get _client => SupabaseService.instance.client;
  static const String _bucket = 'wardrobe-images';
  static String? get currentUserId => SupabaseService.isInitialized
      ? SupabaseService.instance.client.auth.currentUser?.id
      : null;

  static const _signedUrlLifetime = Duration(hours: 1);
  static const _cachedReferencesPreference = 'cached_storage_image_refs';
  static final Map<String, Map<String, String>> _resolvedUrlsByUser = {};
  static final SerialOperationQueue _imageCacheQueue = SerialOperationQueue();

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

  /// Converts recognized legacy project URLs to a stable bucket/object path.
  /// External provider URLs are intentionally left to their caller.
  static String? stableStorageReference(String value, {String? supabaseUrl}) {
    final parsed = _parseStorageReference(value, supabaseUrl: supabaseUrl);
    if (parsed == null) return null;
    return '${parsed.$1}/${parsed.$2}';
  }

  /// Stable owner-scoped cache key for Storage images; external URL behavior
  /// keeps the original URL key.
  static String imageCacheKey(String reference, {String? supabaseUrl}) =>
      stableStorageReference(reference, supabaseUrl: supabaseUrl) ?? reference;

  static String _referencesPreferenceKey(String userId) =>
      '$userId:$_cachedReferencesPreference';

  static String? stableReferenceFor({
    required String bucket,
    required String ownerId,
    required String objectPath,
  }) {
    if (!const ['wardrobe-images', 'avatars'].contains(bucket) ||
        ownerId.isEmpty ||
        objectPath.split('/').first != ownerId ||
        objectPath.split('/').contains('..')) {
      return null;
    }
    return '$bucket/$objectPath';
  }

  /// Returns a stable wardrobe object reference only when the reference is
  /// owned by [ownerId]. External/provider URLs and other users' objects are
  /// deliberately excluded from deletion paths.
  static String? ownedWardrobeImageReference(
    String? value, {
    required String ownerId,
    String? supabaseUrl,
  }) {
    if (value == null || ownerId.isEmpty) return null;
    final reference = stableStorageReference(value, supabaseUrl: supabaseUrl);
    if (reference == null || !isStorageReference(reference)) return null;
    final path = reference.substring('wardrobe-images/'.length);
    if (path.split('/').first != ownerId) return null;
    return reference;
  }

  /// Uploads and returns the stable owner scoped object path for persistence.
  Future<String?> uploadWardrobeImage(String localPath) async {
    return _uploadImage(localPath, bucket: _bucket);
  }

  Future<String?> uploadAvatarImage(String localPath) async {
    return _uploadImage(localPath, bucket: 'avatars');
  }

  Future<String?> _uploadImage(
    String localPath, {
    required String bucket,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final file = File(localPath);
      if (!await file.exists()) return null;

      final extension = localPath.split('.').last.toLowerCase();
      final safeExtension =
          const ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension)
          ? extension
          : 'jpg';
      final contentType = switch (safeExtension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final fileName =
          '$userId/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
      final bytes = await file.readAsBytes();

      await _client.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      if (kDebugMode) debugPrint('Uploaded image reference to $bucket');
      return stableReferenceFor(
        bucket: bucket,
        ownerId: userId,
        objectPath: fileName,
      );
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
      if (parsed == null) {
        return classifyImageReference(reference) == ImageReferenceRoute.network
            ? reference
            : null;
      }
      final userId = _client.auth.currentUser?.id;
      if (userId == null || parsed.$2.split('/').first != userId) return null;
      final signedUrl = await _client.storage
          .from(parsed.$1)
          .createSignedUrl(parsed.$2, _signedUrlLifetime.inSeconds);
      if (_client.auth.currentUser?.id != userId) return null;
      final stableReference = '${parsed.$1}/${parsed.$2}';
      _resolvedUrlsByUser.putIfAbsent(userId, () => {})[stableReference] =
          signedUrl;
      await _rememberImageReference(userId, stableReference);
      return signedUrl;
    } catch (error) {
      if (kDebugMode) debugPrint('Image URL resolution failed: $error');
      return null;
    }
  }

  /// Downloads an image for an export without placing an authorization token
  /// or short-lived signed URL in the exported file.
  Future<Uint8List?> downloadImageBytes(String reference) async {
    try {
      final parsed = _parseStorageReference(reference);
      if (parsed != null) {
        final userId = _client.auth.currentUser?.id;
        if (userId == null || parsed.$2.split('/').first != userId) return null;
        final bytes = await _client.storage.from(parsed.$1).download(parsed.$2);
        if (_client.auth.currentUser?.id != userId) return null;
        return bytes;
      }
      final uri = Uri.tryParse(reference);
      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        return null;
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').startsWith('image/')) {
        return null;
      }
      return response.bodyBytes;
    } catch (error) {
      if (kDebugMode) debugPrint('Image export download failed: $error');
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
        !configured.hasScheme ||
        configured.host.isEmpty ||
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
    final bucketIndex =
        route == 'public' || route == 'sign' || route == 'authenticated'
        ? 4
        : 3;
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
    return deleteImageReference(imageUrl, expectedBucket: _bucket);
  }

  Future<bool> deleteImageReference(
    String reference, {
    String? expectedBucket,
  }) async {
    try {
      final parsed = _parseStorageReference(reference);
      if (parsed == null ||
          (expectedBucket != null && parsed.$1 != expectedBucket)) {
        return false;
      }
      final userId = _client.auth.currentUser?.id;
      if (userId == null || parsed.$2.split('/').first != userId) return false;
      final filePath = parsed.$2;
      await evictImageCacheForReference(
        '${parsed.$1}/$filePath',
        ownerId: userId,
      );
      await _client.storage.from(parsed.$1).remove([filePath]);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting image: $e');
      return false;
    }
  }

  static Future<void> _rememberImageReference(
    String userId,
    String reference,
  ) => _imageCacheQueue.run(() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = _referencesPreferenceKey(userId);
      final references = preferences.getStringList(key) ?? <String>[];
      if (references.contains(reference)) return;
      await preferences.setStringList(key, [...references, reference]);
    } catch (error) {
      if (kDebugMode) debugPrint('Unable to persist image cache reference');
    }
  });

  /// Removes an owner's private image bytes from disk and memory cache without
  /// persisting the signed URL used to fetch them.
  static Future<void> clearImageCacheForUser(String userId) {
    if (userId.isEmpty) return Future<void>.value();
    return _imageCacheQueue.run(() async {
      try {
        final preferences = await SharedPreferences.getInstance();
        final key = _referencesPreferenceKey(userId);
        final references = preferences.getStringList(key) ?? <String>[];
        final resolved = _resolvedUrlsByUser.remove(userId) ?? const {};
        for (final reference in {...references, ...resolved.keys}) {
          final url = resolved[reference] ?? reference;
          await _evictCachedImage(url, reference);
        }
        await preferences.remove(key);
      } catch (error) {
        if (kDebugMode) debugPrint('Unable to clear private image cache');
      }
    });
  }

  static Future<void> evictImageCacheForReference(
    String reference, {
    required String ownerId,
  }) => _imageCacheQueue.run(() async {
    final parsed = _parseStorageReference(reference);
    if (parsed == null || parsed.$2.split('/').first != ownerId) return;
    final stableReference = '${parsed.$1}/${parsed.$2}';
    final url = _resolvedUrlsByUser[ownerId]?.remove(stableReference);
    try {
      await _evictCachedImage(url ?? stableReference, stableReference);
      final preferences = await SharedPreferences.getInstance();
      final key = _referencesPreferenceKey(ownerId);
      final references = preferences.getStringList(key) ?? <String>[];
      references.remove(stableReference);
      if (references.isEmpty) {
        await preferences.remove(key);
      } else {
        await preferences.setStringList(key, references);
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Unable to evict private image cache entry');
    }
  });

  static Future<void> _evictCachedImage(String url, String cacheKey) async {
    await CachedNetworkImage.evictFromCache(url, cacheKey: cacheKey);
    await CachedNetworkImageProvider(url, cacheKey: cacheKey).evict();
  }
}

enum ImageReferenceRoute { storage, network, localFile, asset }
