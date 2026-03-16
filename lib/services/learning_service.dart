import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class LearningService {
  SupabaseClient get _client => SupabaseService.instance.client;

  // ── MODULES ─────────────────────────────────────────────

  /// Fetch all learning modules with user progress
  Future<List<Map<String, dynamic>>> fetchModulesWithProgress() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final modules = await _client
          .from('learning_modules')
          .select()
          .eq('is_active', true)
          .order('order_index', ascending: true);

      final userProgress = await _client
          .from('user_module_progress')
          .select()
          .eq('user_id', userId);

      final progressMap = {
        for (final p in (userProgress as List))
          p['module_id'] as String: p,
      };

      return (modules as List).map((m) {
        final progress = progressMap[m['id'] as String];
        return {
          ...Map<String, dynamic>.from(m),
          'progress': progress != null
              ? (progress['progress'] as num).toDouble()
              : 0.0,
          'is_completed': progress?['completed_at'] != null,
          'started_at': progress?['started_at'],
          'completed_at': progress?['completed_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching modules: $e');
      return [];
    }
  }

  /// Start or update progress on a module
  Future<bool> updateModuleProgress(
      String moduleId, double progress) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('user_module_progress').upsert({
        'user_id': userId,
        'module_id': moduleId,
        'progress': progress,
        'completed_at': progress >= 1.0
            ? DateTime.now().toIso8601String()
            : null,
      }, onConflict: 'user_id, module_id');

      return true;
    } catch (e) {
      debugPrint('Error updating module progress: $e');
      return false;
    }
  }

  // ── USER STATS ──────────────────────────────────────────

  /// Get real user stats needed for unlock logic
  Future<Map<String, dynamic>> getUserLearningStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _emptyStats();

      final outfitLogsResult = await _client
          .from('outfit_logs')
          .select('id')
          .eq('user_id', userId);

      final wardrobeResult = await _client
          .from('wardrobe_items')
          .select('id')
          .eq('user_id', userId);

      final completedModulesResult = await _client
          .from('user_module_progress')
          .select('id')
          .eq('user_id', userId)
          .not('completed_at', 'is', null);

      final outfitsLogged = (outfitLogsResult as List).length;
      final wardrobeItems = (wardrobeResult as List).length;
      final completedModules = (completedModulesResult as List).length;

      // Calculate level based on completed modules
      final level = (completedModules ~/ 3) + 1;

      return {
        'outfits_logged': outfitsLogged,
        'wardrobe_items': wardrobeItems,
        'completed_modules': completedModules,
        'level': level,
      };
    } catch (e) {
      debugPrint('Error fetching learning stats: $e');
      return _emptyStats();
    }
  }

  Map<String, dynamic> _emptyStats() => {
    'outfits_logged': 0,
    'wardrobe_items': 0,
    'completed_modules': 0,
    'level': 1,
  };

  // ── ACHIEVEMENTS ────────────────────────────────────────

  /// Derive achievements from user stats
  List<Map<String, dynamic>> deriveAchievements(
      Map<String, dynamic> stats) {
    final completed = stats['completed_modules'] as int;
    final level = stats['level'] as int;

    return [
      {
        'id': 1,
        'title': 'First Steps',
        'description': 'Completed your first module',
        'icon': 'school',
        'is_unlocked': completed >= 1,
      },
      {
        'id': 2,
        'title': 'Knowledge Seeker',
        'description': 'Completed 3 modules',
        'icon': 'auto_stories',
        'is_unlocked': completed >= 3,
      },
      {
        'id': 3,
        'title': 'Style Scholar',
        'description': 'Reached Level 2',
        'icon': 'workspace_premium',
        'is_unlocked': level >= 2,
      },
      {
        'id': 4,
        'title': 'Halfway There',
        'description': 'Completed 6 modules',
        'icon': 'emoji_events',
        'is_unlocked': completed >= 6,
      },
      {
        'id': 5,
        'title': 'Style Master',
        'description': 'Completed all 12 modules',
        'icon': 'military_tech',
        'is_unlocked': completed >= 12,
      },
    ];
  }
}