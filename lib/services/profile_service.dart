import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './wardrobe_service.dart';
import './purchase_service.dart';
import './outfit_log_service.dart';

class ProfileService {
  SupabaseClient get _client => SupabaseService.instance.client;

  // ── FEEDBACK ─────────────────────────────────────────────
  Future<bool> submitFeedback({
    required String type,
    required String message,
    int? rating,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from('feedback').insert({
        'user_id': userId,
        'type': type,
        'message': message,
        'rating': rating,
        'app_version': '1.0.0',
      });
      return true;
    } catch (e) {
      debugPrint('Feedback error: $e');
      return false;
    }
  }

  // ── CHANGE PASSWORD ──────────────────────────────────────
  Future<String?> changePassword({
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null; // null = success
    } catch (e) {
      debugPrint('Change password error: $e');
      return e.toString();
    }
  }

  // ── PROFILE PHOTO ────────────────────────────────────────
  Future<String?> uploadProfilePhoto(String filePath) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Upload photo error: No user logged in');
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ Upload photo error: File does not exist at $filePath');
        return null;
      }

      // Get file extension
      final ext = filePath.split('.').last.toLowerCase();
      
      // Determine content type
      String contentType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        default:
          contentType = 'image/jpeg';
      }

      // IMPORTANT: Path format must be userId/avatar.ext
      // This matches the RLS policy: (storage.foldername(name))[1] = userId
      final storagePath = '$userId/avatar.$ext';

      debugPrint('📤 Uploading to avatars bucket: $storagePath');
      debugPrint('📤 Content type: $contentType');

      // Upload to avatars bucket
      await _client.storage.from('avatars').upload(
        storagePath,
        file,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      // Get public URL
      final publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      debugPrint('✅ Upload successful! URL: $publicUrl');

      // Save to user metadata
      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      // Also save to user_profiles table
      try {
        await _client.from('user_profiles').upsert({
          'id': userId,
          'avatar_url': publicUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Updated user_profiles table');
      } catch (e) {
        // Non-fatal: table might not exist or have different columns
        debugPrint('⚠️ Could not update user_profiles table: $e');
      }

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('❌ Storage error: ${e.message}');
      debugPrint('❌ Error code: ${e.errorCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Upload photo error: $e');
      return null;
    }
  }

  // ── EXPORT DATA ──────────────────────────────────────────
  Future<String?> exportAsCSV() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final wardrobeService = WardrobeService();
      final purchaseService = PurchaseService();
      final outfitService = OutfitLogService();

      final wardrobe = await wardrobeService.fetchWardrobeItems();
      final purchases = await purchaseService.fetchPurchases();
      final outfits = await outfitService.fetchOutfitLogsForDate(
        DateTime.now().subtract(const Duration(days: 365)),
      );

      final buffer = StringBuffer();

      // Wardrobe section
      buffer.writeln('WARDROBE ITEMS');
      buffer.writeln('Name,Category,Brand,Color,Purchase Price,Times Worn');
      for (final item in wardrobe) {
        buffer.writeln([
          _csvField(item['name']),
          _csvField(item['category']),
          _csvField(item['brand']),
          _csvField(item['color']),
          _csvField(item['purchase_price']?.toString()),
          _csvField(item['times_worn']?.toString()),
        ].join(','));
      }

      buffer.writeln('');
      buffer.writeln('PURCHASES');
      buffer.writeln('Name,Brand,Category,Price,Date');
      for (final p in purchases) {
        buffer.writeln([
          _csvField(p['name']),
          _csvField(p['brand']),
          _csvField(p['category']),
          _csvField(p['price']?.toString()),
          _csvField(p['purchase_date']),
        ].join(','));
      }

      buffer.writeln('');
      buffer.writeln('OUTFIT LOGS');
      buffer.writeln('Date,Occasion,Rating,Notes');
      for (final o in outfits) {
        buffer.writeln([
          _csvField(o['worn_date']),
          _csvField(o['occasion']),
          _csvField(o['rating']?.toString()),
          _csvField(o['notes']),
        ].join(','));
      }

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/everywear_export_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      debugPrint('Export CSV error: $e');
      return null;
    }
  }

  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  String _csvField(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}