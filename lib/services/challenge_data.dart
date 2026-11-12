List<Map<String, dynamic>> mergeChallengeData({
  Map<String, dynamic>? current,
  required List<Map<String, dynamic>> history,
}) {
  final challenges = <Map<String, dynamic>>[];
  final seenIds = <String>{};

  if (current != null) {
    challenges.add(Map<String, dynamic>.from(current));
    final id = current['id'];
    if (id is String) seenIds.add(id);
  }

  for (final entry in history) {
    final related = entry['style_challenges'];
    if (related is! Map) continue;

    final challenge = Map<String, dynamic>.from(related);
    final id = entry['challenge_id'] ?? challenge['id'];
    if (id is! String || !seenIds.add(id)) continue;

    challenges.add({
      ...challenge,
      'is_joined': true,
      'progress': entry['progress'] ?? 0,
      'completed_at': entry['completed_at'],
      'insight': entry['insight'],
      'user_challenge_id': entry['id'],
      'anchor_item_id': entry['anchor_item_id'],
    });
  }

  return challenges;
}
