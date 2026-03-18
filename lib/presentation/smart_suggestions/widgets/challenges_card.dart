import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/utils/app_localizations.dart';
import '../../../services/challenge_service.dart';
import 'challenge_detail_sheet.dart';

/// Drop-in replacement for the empty challenges card in [SmartSuggestions].
///
/// Usage — replace [_buildChallengesSection] call in SmartSuggestions with:
/// ```dart
/// ChallengesCard(isPremium: _isPremium),
/// ```
class ChallengesCard extends StatefulWidget {
  final bool isPremium;

  const ChallengesCard({Key? key, required this.isPremium}) : super(key: key);

  @override
  State<ChallengesCard> createState() => _ChallengesCardState();
}

class _ChallengesCardState extends State<ChallengesCard> {
  final ChallengeService _service = ChallengeService();
  Map<String, dynamic>? _challenge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _service.fetchCurrentChallenge();
    if (mounted) {
      setState(() {
        _challenge = data;
        _isLoading = false;
      });
    }
  }

  String _getLocalizedTitle(String type, AppLocalizations loc) {
    switch (type) {
      case 'anchor_piece': return loc.translate('challenge_type_anchor_title');
      case 'rediscover':   return loc.translate('challenge_type_rediscover_title');
      case 'color_outfit': return loc.translate('challenge_type_color_title');
      case 'capsule':      return loc.translate('challenge_type_capsule_title');
      case 'minimalist':   return loc.translate('challenge_type_minimalist_title');
      case 'vintage':      return loc.translate('challenge_type_vintage_title');
      case 'monochrome':   return loc.translate('challenge_type_monochrome_title');
      case 'pattern_mix':  return loc.translate('challenge_type_pattern_mix_title');
      default:             return _challenge?['title'] as String? ?? '';
    }
  }

  String _getLocalizedDescription(String type, AppLocalizations loc) {
    switch (type) {
      case 'anchor_piece': return loc.translate('challenge_type_anchor_description');
      case 'rediscover':   return loc.translate('challenge_type_rediscover_description');
      case 'color_outfit': return loc.translate('challenge_type_color_description');
      case 'capsule':      return loc.translate('challenge_type_capsule_description');
      case 'minimalist':   return loc.translate('challenge_type_minimalist_description');
      case 'vintage':      return loc.translate('challenge_type_vintage_description');
      case 'monochrome':   return loc.translate('challenge_type_monochrome_description');
      case 'pattern_mix':  return loc.translate('challenge_type_pattern_mix_description');
      default:             return _challenge?['description'] as String? ?? '';
    }
  }

  void _openDetail() async {
    if (_challenge == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChallengeDetailSheet(
        challenge: _challenge!,
        service: _service,
        isPremium: widget.isPremium,
        onChanged: _load,
      ),
    );
    // Refresh after sheet closes (user may have joined or logged progress)
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return _buildSkeleton(theme);
    if (_challenge == null) return _buildEmpty(theme);

    final isJoined = _challenge!['is_joined'] as bool? ?? false;
    final progress = _challenge!['progress'] as int? ?? 0;
    final goal = _challenge!['goal'] as int? ?? 1;
    final isComplete = progress >= goal;
    final progressFraction = goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0;
    final type = _challenge!['type'] as String? ?? '';

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.07)
              : isJoined
                  ? theme.colorScheme.primary.withValues(alpha: 0.07)
                  : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isComplete
                ? Colors.green.withValues(alpha: 0.35)
                : isJoined
                    ? theme.colorScheme.primary.withValues(alpha: 0.30)
                    : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isJoined ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: emoji + title + arrow ──────────────────────────
            Row(
              children: [
                _TypeBadge(type: type, theme: theme, isComplete: isComplete),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedTitle(type, AppLocalizations.of(context)),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.3.h),
                      _WeekChip(theme: theme),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),

            SizedBox(height: 1.8.h),

            // ── Description ─────────────────────────────────────────────
            Text(
              _getLocalizedDescription(type, AppLocalizations.of(context)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 2.h),

            // ── Progress or Join button ──────────────────────────────────
            if (isJoined) ...[
              _ProgressBar(
                fraction: progressFraction,
                isComplete: isComplete,
                theme: theme,
              ),
              SizedBox(height: 0.8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isComplete
                        ? AppLocalizations.of(context).challengeCompleteInline
                        : '$progress / $goal ${AppLocalizations.of(context).outfits}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isComplete
                          ? Colors.green.shade700
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isComplete)
                    Text(
                      'Tap to log progress',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openDetail,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.3.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Accept Challenge',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty / skeleton ────────────────────────────────────────────────────

  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 18.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Shimmer(width: 40.w, height: 2.h, theme: theme),
          SizedBox(height: 1.h),
          _Shimmer(width: double.infinity, height: 1.5.h, theme: theme),
          SizedBox(height: 0.8.h),
          _Shimmer(width: 60.w, height: 1.5.h, theme: theme),
          SizedBox(height: 2.h),
          _Shimmer(width: double.infinity, height: 4.h, theme: theme),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 42, color: Colors.grey.shade300),
          SizedBox(height: 1.h),
          Text(
            'No challenge this week',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: Colors.grey.shade500),
          ),
          Text(
            'Check back soon',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  final ThemeData theme;
  final bool isComplete;

  const _TypeBadge({
    required this.type,
    required this.theme,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiFor(type);
    return Container(
      width: 13.w,
      height: 13.w,
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  String _emojiFor(String type) {
    switch (type) {
      case 'anchor_piece': return '⚓';
      case 'rediscover':   return '🔍';
      case 'color_outfit': return '🎨';
      case 'capsule':      return '✨';
      default:             return '🏆';
    }
  }
}

class _WeekChip extends StatelessWidget {
  final ThemeData theme;
  const _WeekChip({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
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
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double fraction;
  final bool isComplete;
  final ThemeData theme;

  const _ProgressBar({
    required this.fraction,
    required this.isComplete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 7,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
        valueColor: AlwaysStoppedAnimation(
          isComplete ? Colors.green : theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final ThemeData theme;

  const _Shimmer({required this.width, required this.height, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}