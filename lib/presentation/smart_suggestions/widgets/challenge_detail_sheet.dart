import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/challenge_service.dart';
import '../../../services/supabase_service.dart';
import '../../../core/utils/app_localizations.dart';

/// Full-screen bottom sheet shown when user taps a challenge card.
/// Handles: join flow, anchor item selection, progress logging, insight reveal.
class ChallengeDetailSheet extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final ChallengeService service;
  final bool isPremium;
  final VoidCallback onChanged;

  const ChallengeDetailSheet({
    Key? key,
    required this.challenge,
    required this.service,
    required this.isPremium,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ChallengeDetailSheet> createState() => _ChallengeDetailSheetState();
}

class _ChallengeDetailSheetState extends State<ChallengeDetailSheet> {
  late Map<String, dynamic> _challenge;
  bool _isLoading = false;

  // Anchor piece selection
  List<Map<String, dynamic>> _wardrobeItems = [];
  Map<String, dynamic>? _selectedAnchorItem;
  bool _loadingWardrobe = false;

  // Suggested unworn item (for rediscover type)
  Map<String, dynamic>? _suggestedItem;

  @override
  void initState() {
    super.initState();
    _challenge = Map<String, dynamic>.from(widget.challenge);
    _maybeLoadExtras();
  }

  Future<void> _maybeLoadExtras() async {
    final type = _challenge['type'] as String? ?? '';
    final isJoined = _challenge['is_joined'] as bool? ?? false;

    if (type == 'anchor_piece' && !isJoined) {
      await _loadWardrobeItems();
    }
    if (type == 'rediscover' && !isJoined) {
      final item = await widget.service.fetchLongestUnwornItem();
      if (mounted) setState(() => _suggestedItem = item);
    }
  }

  Future<void> _loadWardrobeItems() async {
    setState(() => _loadingWardrobe = true);
    try {
      final uid = SupabaseService.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final rows = await SupabaseService.instance.client
          .from('wardrobe_items')
          .select('id, name, image_url, category')
          .eq('user_id', uid)
          .order('name')
          .limit(50);
      if (mounted) {
        setState(() {
          _wardrobeItems = List<Map<String, dynamic>>.from(rows);
        });
      }
    } catch (e) {
      debugPrint('ChallengeDetailSheet._loadWardrobeItems error: $e');
    } finally {
      if (mounted) setState(() => _loadingWardrobe = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _join() async {
    final type = _challenge['type'] as String? ?? '';
    if (type == 'anchor_piece' && _selectedAnchorItem == null) {
      _showSnack('Please pick an anchor item first.');
      return;
    }

    setState(() => _isLoading = true);
    final success = await widget.service.joinChallenge(
      _challenge['id'] as String,
      anchorItemId: _selectedAnchorItem?['id'] as String?,
    );

    if (!mounted) return;
    if (success) {
      widget.onChanged();
      // Refresh local state
      setState(() {
        _challenge['is_joined'] = true;
        _challenge['progress'] = 0;
        _challenge['anchor_item_id'] = _selectedAnchorItem?['id'];
      });
      _showSnack('Challenge accepted! 🎉');
    } else {
      _showSnack('Something went wrong. Please try again.', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logProgress() async {
    final userChallengeId = _challenge['user_challenge_id'] as String?;
    if (userChallengeId == null) return;

    final type = _challenge['type'] as String? ?? '';
    final currentProgress = _challenge['progress'] as int? ?? 0;
    final goal = _challenge['goal'] as int? ?? 1;

    if (currentProgress >= goal) {
      _showSnack('Challenge already complete ✅');
      return;
    }

    setState(() => _isLoading = true);

    // Get anchor item name if relevant
    String? anchorName;
    if (type == 'anchor_piece' && _challenge['anchor_item_id'] != null) {
      final match = _wardrobeItems.where(
        (i) => i['id'] == _challenge['anchor_item_id'],
      );
      anchorName = match.isNotEmpty ? match.first['name'] as String? : null;

      // Lazy-load if wardrobe wasn't fetched (user was already joined)
      if (anchorName == null && _wardrobeItems.isEmpty) {
        await _loadWardrobeItems();
        final match2 = _wardrobeItems.where(
          (i) => i['id'] == _challenge['anchor_item_id'],
        );
        anchorName = match2.isNotEmpty ? match2.first['name'] as String? : null;
      }
    }

    final result = await widget.service.incrementProgress(
      userChallengeId: userChallengeId,
      currentProgress: currentProgress,
      goal: goal,
      challengeType: type,
      anchorItemName: anchorName,
    );

    if (!mounted) return;

    setState(() {
      _challenge['progress'] = result['progress'];
      if (result['is_complete'] == true) {
        _challenge['completed_at'] = DateTime.now().toIso8601String();
        _challenge['insight'] = result['insight'];
      }
      _isLoading = false;
    });

    widget.onChanged();

    if (result['is_complete'] == true) {
      _showInsightDialog(result['insight'] as String? ?? '');
    } else {
      _showSnack('Progress logged! Keep going 💪');
    }
  }

  void _showInsightDialog(String insight) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('✨', style: TextStyle(fontSize: 40)),
            SizedBox(height: 1.h),
            Text(
              'Style Insight Unlocked',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            insight,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.2.h),
            ),
            child: Text(AppLocalizations.of(context).challengeInsightCta),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = _challenge['type'] as String? ?? '';
    final isJoined = _challenge['is_joined'] as bool? ?? false;
    final progress = _challenge['progress'] as int? ?? 0;
    final goal = _challenge['goal'] as int? ?? 1;
    final isComplete = progress >= goal;
    final insight = _challenge['insight'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                _EmojiBox(type: type, theme: theme, isComplete: isComplete),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context).challengeWeeklyLabel,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _challenge['title'] as String? ?? '',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.5.h),

            // ── Description ─────────────────────────────────────────────
            Text(
              _challenge['description'] as String? ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),

            SizedBox(height: 1.5.h),

            _InfoRow(
              theme: theme,
              icon: Icons.calendar_today_outlined,
              text: '${_challenge['duration_days'] ?? 7} days',
            ),
            SizedBox(height: 0.6.h),
            _InfoRow(
              theme: theme,
              icon: Icons.flag_outlined,
              text: 'Goal: $goal outfit${goal == 1 ? '' : 's'}',
            ),

            SizedBox(height: 3.h),

            // ── Type-specific extras ────────────────────────────────────
            if (type == 'anchor_piece') ...[
              _buildAnchorSection(theme, isJoined),
              SizedBox(height: 2.h),
            ],

            if (type == 'rediscover' && _suggestedItem != null && !isJoined) ...[
              _buildRediscoverSuggestion(theme),
              SizedBox(height: 2.h),
            ],

            if (type == 'color_outfit' && !isJoined) ...[
              _buildColorTip(theme),
              SizedBox(height: 2.h),
            ],

            if (type == 'capsule' && !isJoined) ...[
              _buildCapsuleTip(theme),
              SizedBox(height: 2.h),
            ],

            // ── Progress bar (joined) ───────────────────────────────────
            if (isJoined) ...[
              _buildProgressSection(theme, progress, goal, isComplete),
              SizedBox(height: 2.5.h),
            ],

            // ── Insight (completed) ─────────────────────────────────────
            if (isComplete && insight != null) ...[
              _buildInsightCard(theme, insight),
              SizedBox(height: 2.5.h),
            ],

            // ── CTA ─────────────────────────────────────────────────────
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!isJoined)
              _JoinButton(
                onTap: _join,
                theme: theme,
                enabled: type != 'anchor_piece' || _selectedAnchorItem != null,
              )
            else if (!isComplete)
              _LogButton(onTap: _logProgress, theme: theme)
            else
              _CompleteState(theme: theme),
          ],
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildAnchorSection(ThemeData theme, bool isJoined) {
    if (isJoined) {
      // Show the chosen anchor item name
      final anchorId = _challenge['anchor_item_id'] as String?;
      if (anchorId == null) return const SizedBox.shrink();

      final match = _wardrobeItems.where((i) => i['id'] == anchorId);
      final name = match.isNotEmpty
          ? match.first['name'] as String?
          : 'Your anchor piece';

      return _TipCard(
        theme: theme,
        icon: '⚓',
        title: 'Your anchor piece',
        body: name ?? 'Anchor piece',
        color: theme.colorScheme.primary,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick your anchor piece',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'This is the item you\'ll build 3 outfits around.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.5.h),
        if (_loadingWardrobe)
          const Center(child: CircularProgressIndicator())
        else if (_wardrobeItems.isEmpty)
          Text(
            'No wardrobe items found. Add items first.',
            style: theme.textTheme.bodySmall,
          )
        else
          _AnchorItemPicker(
            items: _wardrobeItems,
            selected: _selectedAnchorItem,
            theme: theme,
            onSelect: (item) => setState(() => _selectedAnchorItem = item),
          ),
      ],
    );
  }

  Widget _buildRediscoverSuggestion(ThemeData theme) {
    final name = _suggestedItem!['name'] as String? ?? 'an item';
    final lastWorn = _suggestedItem!['last_worn'] as String?;
    final daysSince = lastWorn != null
        ? DateTime.now()
            .difference(DateTime.parse(lastWorn))
            .inDays
        : null;

    return _TipCard(
      theme: theme,
      icon: '🔍',
      title: 'Suggested for you',
      body: daysSince != null
          ? '"$name" — unworn for $daysSince days'
          : '"$name" — not worn yet',
      color: Colors.orange,
    );
  }

  Widget _buildColorTip(ThemeData theme) {
    return _TipCard(
      theme: theme,
      icon: '💡',
      title: 'Stylist tip',
      body: 'Try navy, camel, or olive — these tonal families are the '
          'easiest to build a full outfit around.',
      color: Colors.purple,
    );
  }

  Widget _buildCapsuleTip(ThemeData theme) {
    return _TipCard(
      theme: theme,
      icon: '💡',
      title: 'How it works',
      body: 'Choose 7 items from your wardrobe. Log 5 different outfits '
          'using only those pieces throughout the week.',
      color: Colors.teal,
    );
  }

  Widget _buildProgressSection(
    ThemeData theme,
    int progress,
    int goal,
    bool isComplete,
  ) {
    final fraction = goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '$progress / $goal outfits',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isComplete ? Colors.green : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(
              isComplete ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(ThemeData theme, String insight) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Style Insight',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  insight,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _EmojiBox extends StatelessWidget {
  final String type;
  final ThemeData theme;
  final bool isComplete;

  const _EmojiBox(
      {required this.type,
      required this.theme,
      required this.isComplete});

  String get _emoji {
    switch (type) {
      case 'anchor_piece': return '⚓';
      case 'rediscover':   return '🔍';
      case 'color_outfit': return '🎨';
      case 'capsule':      return '✨';
      default:             return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 28))),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String text;

  const _InfoRow(
      {required this.theme, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: 2.w),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final ThemeData theme;
  final String icon;
  final String title;
  final String body;
  final Color color;

  const _TipCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  body,
                  style:
                      theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnchorItemPicker extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? selected;
  final ThemeData theme;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _AnchorItemPicker({
    required this.items,
    required this.selected,
    required this.theme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 2.w),
        itemBuilder: (_, index) {
          final item = items[index];
          final isSelected = selected?['id'] == item['id'];
          return GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                item['name'] as String? ?? 'Item',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final VoidCallback onTap;
  final ThemeData theme;
  final bool enabled;

  const _JoinButton(
      {required this.onTap,
      required this.theme,
      required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'Accept Challenge',
          style:
              TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final VoidCallback onTap;
  final ThemeData theme;

  const _LogButton({required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_circle_outline),
        label: Text(
          'Log Outfit Progress',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: BorderSide(
              color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _CompleteState extends StatelessWidget {
  final ThemeData theme;
  const _CompleteState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          SizedBox(height: 0.5.h),
          Text(
            'Challenge Complete!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          Text(
            'New challenge arrives next week.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}