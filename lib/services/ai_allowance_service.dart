import 'package:supabase_flutter/supabase_flutter.dart';

/// A display-only snapshot. Every AI operation is still enforced atomically by
/// reserve_ai_action; this snapshot can be stale by the time a request runs.
class AiAllowanceSnapshot {
  const AiAllowanceSnapshot({
    required this.monthRemaining,
    required this.monthLimit,
    required this.dayRemaining,
    required this.burstRemaining,
    required this.monthResetsAt,
  });

  final int monthRemaining;
  final int monthLimit;
  final int dayRemaining;
  final int burstRemaining;
  final DateTime? monthResetsAt;

  static AiAllowanceSnapshot? tryParse(Object? value) {
    if (value is! Map) return null;
    final remaining = value['month_remaining'];
    final limit = value['month_limit'];
    final dayRemaining = value['day_remaining'];
    final burstRemaining = value['burst_remaining'];
    if (remaining is! num ||
        limit is! num ||
        dayRemaining is! num ||
        burstRemaining is! num ||
        limit <= 0) {
      return null;
    }
    return AiAllowanceSnapshot(
      monthRemaining: remaining.toInt().clamp(0, limit.toInt()),
      monthLimit: limit.toInt(),
      dayRemaining: dayRemaining.toInt().clamp(0, 20),
      burstRemaining: burstRemaining.toInt().clamp(0, 5),
      monthResetsAt: DateTime.tryParse(
        value['month_resets_at']?.toString() ?? '',
      ),
    );
  }

  bool get canRequest =>
      monthRemaining > 0 && dayRemaining > 0 && burstRemaining > 0;
}

class AiAllowanceService {
  AiAllowanceService(this._client);

  final SupabaseClient _client;

  Future<AiAllowanceSnapshot> fetchCurrent() async {
    final response = await _client.rpc('get_ai_allowance');
    final snapshot = AiAllowanceSnapshot.tryParse(response);
    if (snapshot == null)
      throw const FormatException('AI allowance unavailable');
    return snapshot;
  }
}
