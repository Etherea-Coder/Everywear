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
      if (userId == null) return null;

      final file = File(filePath);
      final ext = filePath.split('.').last.toLowerCase();
      final storagePath = 'avatars/$userId/avatar.$ext';

      await _client.storage.from('wardrobe-images').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _client.storage
          .from('wardrobe-images')
          .getPublicUrl(storagePath);

      // Save to user metadata
      await _client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      // Also save to user_profiles table
      await _client.from('user_profiles').upsert({
        'id': userId,
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return publicUrl;
    } catch (e) {
      debugPrint('Upload photo error: $e');
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
