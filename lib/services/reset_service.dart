import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // Order matters: delete children before parents to respect FK constraints.
    // outfit_items references outfit_logs → delete outfit_items first.
    final steps = [
      _ResetStep('outfit_items',   () => _deleteViaJoin(userId)),
      _ResetStep('outfit_logs',    () => _delete('outfit_logs', userId)),
      _ResetStep('wardrobe_items', () => _delete('wardrobe_items', userId)),
      _ResetStep('purchases',      () => _delete('purchases', userId)),
      _ResetStep('wishlist',       () => _delete('wishlist', userId)),
      _ResetStep('user_challenges',() => _delete('user_challenges', userId)),
      _ResetStep('style_events',   () => _delete('style_events', userId)),
      _ResetStep('style_quiz_results', () => _delete('style_quiz_results', userId)),
      _ResetStep('user_budget',    () => _delete('user_budget', userId)),
      _ResetStep('user_module_progress', () => _delete('user_module_progress', userId)),
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
    // Fetch the user's outfit log IDs first
    final logs = await _client
        .from('outfit_logs')
        .select('id')
        .eq('user_id', userId);

    if (logs.isEmpty) return;

    final ids = (logs as List).map((r) => r['id'] as String).toList();
    await _client.from('outfit_items').delete().inFilter('outfit_id', ids);
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