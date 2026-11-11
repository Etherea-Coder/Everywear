import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './paginated_outfit_link_cleanup.dart';
import './storage_service.dart';
import './supabase_service.dart';

/// Handles full account data reset.
/// Deletes all user-generated data from Supabase while keeping the
/// auth account intact. Local preferences are cleared by the caller.
class ResetService {
  SupabaseClient get _client => SupabaseService.instance.client;

  /// Deletes all data for the current user across every relevant table.
  /// Returns a [ResetResult] describing success or which step failed.
  Future<ResetResult> resetAllUserData() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return ResetResult.failure('User not authenticated');
    }

    // Invalidate private image bytes before any remote deletes can partially
    // succeed. A failed reset can then reload remaining objects if retried.
    await StorageService.clearImageCacheForUser(userId);

    // Order matters: delete children before parents to respect FK constraints.
    // outfit_items references outfit_logs → delete outfit_items first.
    final steps = [
      _ResetStep('outfit_items', () => _deleteViaJoin(userId)),
      _ResetStep('outfit_logs', () => _delete('outfit_logs', userId)),
      _ResetStep('wardrobe_items', () => _delete('wardrobe_items', userId)),
      _ResetStep('purchases', () => _delete('purchases', userId)),
      _ResetStep('wishlist', () => _delete('wishlist', userId)),
      _ResetStep('user_challenges', () => _delete('user_challenges', userId)),
      _ResetStep('style_events', () => _delete('style_events', userId)),
      _ResetStep(
        'style_quiz_results',
        () => _delete('style_quiz_results', userId),
      ),
      _ResetStep('user_budget', () => _delete('user_budget', userId)),
      _ResetStep(
        'user_module_progress',
        () => _delete('user_module_progress', userId),
      ),
      _ResetStep('feedback', () => _delete('feedback', userId)),
      _ResetStep(
        'wardrobe-images',
        () => _clearStorageBucket('wardrobe-images', userId),
      ),
      _ResetStep('avatars', () => _clearStorageBucket('avatars', userId)),
      _ResetStep('user_profiles', () => _resetProfile(userId)),
    ];

    for (final step in steps) {
      try {
        await step.action();
        if (kDebugMode) debugPrint('✅ Reset: cleared ${step.table}');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Reset failed at ${step.table}: $e');
        return ResetResult.failure('Failed to clear ${step.table}: $e');
      }
    }

    return ResetResult.success();
  }

  /// Deletes rows directly owned by the user.
  Future<void> _delete(String table, String userId) async {
    await _client.from(table).delete().eq('user_id', userId);
  }

  /// outfit_items has no user_id — delete via outfit_id references.
  Future<void> _deleteViaJoin(String userId) async {
    await deleteOutfitLinksInPages(
      loadLogIds: (offset, limit) async {
        final logs = await _client
            .from('outfit_logs')
            .select('id')
            .eq('user_id', userId)
            .order('id', ascending: true)
            .range(offset, offset + limit - 1);
        return logs.map((row) => row['id'] as String).toList(growable: false);
      },
      deleteLinks: (outfitIds) async {
        await _client
            .from('outfit_items')
            .delete()
            .inFilter('outfit_id', outfitIds);
      },
    );
  }

  Future<void> _clearStorageBucket(String bucket, String userId) async {
    final paths = <String>[];

    Future<void> collect(String folder) async {
      var offset = 0;
      while (true) {
        final entries = await _client.storage
            .from(bucket)
            .list(
              path: folder,
              searchOptions: SearchOptions(limit: 100, offset: offset),
            );
        if (entries.isEmpty) break;
        for (final entry in entries) {
          final path = '$folder/${entry.name}';
          if (entry.id == null && entry.metadata == null) {
            await collect(path);
          } else {
            paths.add(path);
          }
        }
        if (entries.length < 100) break;
        offset += entries.length;
      }
    }

    await collect(userId);
    for (var index = 0; index < paths.length; index += 100) {
      final end = index + 100 < paths.length ? index + 100 : paths.length;
      await _client.storage.from(bucket).remove(paths.sublist(index, end));
    }
  }

  Future<void> _resetProfile(String userId) async {
    await _client
        .from('user_profiles')
        .update({
          'avatar_url': null,
          'onboarding_completed': false,
          'style_preferences': <String>[],
          'work_environment': null,
          'social_frequency': null,
          'climate': null,
          'purchase_frequency': 3.0,
          'budget_consciousness': 3.0,
          'environmental_impact': 3.0,
        })
        .eq('id', userId);
    await _client.auth.updateUser(UserAttributes(data: {'avatar_url': null}));
  }
}

class _ResetStep {
  final String table;
  final Future<void> Function() action;
  const _ResetStep(this.table, this.action);
}

class ResetResult {
  final bool success;
  final String? errorMessage;

  const ResetResult._({required this.success, this.errorMessage});

  factory ResetResult.success() => const ResetResult._(success: true);
  factory ResetResult.failure(String message) =>
      ResetResult._(success: false, errorMessage: message);
}
