import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './wardrobe_service.dart';
import './purchase_service.dart';
import './outfit_log_service.dart';
import './storage_service.dart';

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
      if (kDebugMode) debugPrint('Feedback error: $e');
      return false;
    }
  }

  // ── CHANGE PASSWORD ──────────────────────────────────────
  Future<String?> changePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null; // null = success
    } catch (e) {
      if (kDebugMode) debugPrint('Change password error: $e');
      return e.toString();
    }
  }

  // ── PROFILE PHOTO ────────────────────────────────────────
  Future<String?> uploadProfilePhoto(String filePath) async {
    final userId = _client.auth.currentUser?.id;
    final oldReference = _client.auth.currentUser?.userMetadata?['avatar_url']
        ?.toString();
    if (userId == null) return null;
    try {
      final reference = await StorageService().uploadAvatarImage(filePath);
      if (reference == null) return null;
      if (_client.auth.currentUser?.id != userId) {
        await StorageService().deleteImageReference(
          reference,
          expectedBucket: 'avatars',
        );
        return null;
      }

      try {
        await _client.auth.updateUser(
          UserAttributes(data: {'avatar_url': reference}),
        );
      } catch (_) {
        await StorageService().deleteImageReference(
          reference,
          expectedBucket: 'avatars',
        );
        rethrow;
      }
      if (_client.auth.currentUser?.id != userId) return null;

      var profileMirrorSaved = false;
      try {
        await _client
            .from('user_profiles')
            .update({
              'avatar_url': reference,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
        profileMirrorSaved = true;
      } catch (e) {
        if (kDebugMode) debugPrint('Profile avatar metadata update failed: $e');
      }

      if (_client.auth.currentUser?.id != userId) return null;

      if (profileMirrorSaved &&
          oldReference != null &&
          oldReference != reference) {
        await StorageService().deleteImageReference(
          oldReference,
          expectedBucket: 'avatars',
        );
      }
      return reference;
    } on StorageException catch (e) {
      if (kDebugMode) debugPrint('❌ Storage error: ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Upload photo error: $e');
      return null;
    }
  }

  Future<bool> deleteProfilePhoto() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final userId = user.id;
    final oldReference = user.userMetadata?['avatar_url']?.toString();
    try {
      await _client.auth.updateUser(UserAttributes(data: {'avatar_url': null}));
      if (_client.auth.currentUser?.id != userId) return false;
      var profileMirrorCleared = false;
      try {
        await _client
            .from('user_profiles')
            .update({
              'avatar_url': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
        profileMirrorCleared = true;
      } catch (error) {
        if (kDebugMode) debugPrint('Profile avatar clear failed: $error');
      }
      if (_client.auth.currentUser?.id != userId) return false;
      if (profileMirrorCleared && oldReference != null) {
        await StorageService().deleteImageReference(
          oldReference,
          expectedBucket: 'avatars',
        );
      }
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Profile photo deletion failed: $error');
      return false;
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
        buffer.writeln(
          [
            _csvField(item['name']),
            _csvField(item['category']),
            _csvField(item['brand']),
            _csvField(item['color']),
            _csvField(item['purchase_price']?.toString()),
            _csvField(item['times_worn']?.toString()),
          ].join(','),
        );
      }

      buffer.writeln('');
      buffer.writeln('PURCHASES');
      buffer.writeln('Name,Brand,Category,Price,Date');
      for (final p in purchases) {
        buffer.writeln(
          [
            _csvField(p['name']),
            _csvField(p['brand']),
            _csvField(p['category']),
            _csvField(p['price']?.toString()),
            _csvField(p['purchase_date']),
          ].join(','),
        );
      }

      buffer.writeln('');
      buffer.writeln('OUTFIT LOGS');
      buffer.writeln('Date,Occasion,Rating,Notes');
      for (final o in outfits) {
        buffer.writeln(
          [
            _csvField(o['worn_date']),
            _csvField(o['occasion']),
            _csvField(o['rating']?.toString()),
            _csvField(o['notes']),
          ].join(','),
        );
      }

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/everywear_export_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      if (kDebugMode) debugPrint('Export CSV error: $e');
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
