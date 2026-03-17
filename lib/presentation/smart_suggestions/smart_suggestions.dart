import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../services/style_service.dart';
import '../../services/user_tier_service.dart';
import '../../widgets/upgrade_prompt_widget.dart';
import '../../core/utils/app_localizations.dart';

class SmartSuggestions extends StatefulWidget {
  const SmartSuggestions({Key? key}) : super(key: key);

  @override
  State<SmartSuggestions> createState() => _SmartSuggestionsState();
}

class _SmartSuggestionsState extends State<SmartSuggestions> {
  final StyleService _styleService = StyleService();
  final UserTierService _tierService = UserTierService();
  bool _isPremium = false;
  Map<String, dynamic> _coachingQuota = {
    'used': 0,
    'limit': 1,
    'remaining': 1,
    'period': 'this week',
  };

  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _challenges = [];
  Map<String, dynamic> _insights = {};
  Map<String, dynamic>? _quizResult;
  bool _isLoading = true;
  String _coachTip = '';
  bool _isCoachTipLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTierInfo();
  }

  Future<void> _loadTierInfo() async {
    final user = _styleService.client.auth.currentUser;
    if (user == null) return;
    final isPremium = await _tierService.isPremium();
    final quota = await _tierService.getCoachingQuota(user.id);
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _coachingQuota = quota;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _styleService.fetchUpcomingEvents(),
      _styleService.fetchChallenges(),
      _styleService.fetchStyleInsights(),
      _styleService.fetchQuizResult(),
    ]);
    if (mounted) {
      setState(() {
        _events = results[0] as List<Map<String, dynamic>>;
        _challenges = results[1] as List<Map<String, dynamic>>;
        _insights = results[2] as Map<String, dynamic>;
        _quizResult = results[3] as Map<String, dynamic>?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              title: Text(AppLocalizations.of(context).styleTitle, style: theme.textTheme.headlineMedium),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                  onPressed: _loadData,
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Style Quiz section
                    _buildQuizSection(theme),
                    SizedBox(height: 3.h),
                    // Coach section
                    _buildSectionHeader(theme, localizations.styleCoach, Icons.psychology_alt),
                    SizedBox(height: 1.h),
                    _buildCoachSection(theme),
                    SizedBox(height: 3.h),
                    // Events section
                    _buildSectionHeader(theme, localizations.events, Icons.event,
                        onAdd: _showAddEventDialog),
                    SizedBox(height: 1.h),
                    _buildEventsSection(theme),
                    SizedBox(height: 3.h),
                    // Challenges section
                    _buildSectionHeader(theme, localizations.challenges, Icons.flag),
                    SizedBox(height: 1.h),
                    _buildChallengesSection(theme),
                    SizedBox(height: 3.h),
                    // Insights section
                    _buildSectionHeader(theme, localizations.insights, Icons.insights),
                    SizedBox(height: 1.h),
                    _buildInsightsSection(theme),
                    SizedBox(height: 10.h),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── EVENTS ──────────────────────────────────────────────
  Widget _buildEventsSection(ThemeData theme) {
    final localizations = AppLocalizations.of(context);
    if (_events.isEmpty) {
      return _buildEmptyCard(
        theme,
        icon: Icons.event_available,
        title: localizations.noUpcomingEvents,
        subtitle: localizations.addEventForSuggestions,
        actionLabel: localizations.addEvent,
        onAction: _showAddEventDialog,
      );
    }

    return Column(
      children: _events.map((event) => _buildEventCard(theme, event)).toList(),
    );
  }

  Widget _buildEventCard(ThemeData theme, Map<String, dynamic> event) {
    final localizations = AppLocalizations.of(context);
    final date = DateTime.parse(event['event_date']);
    final daysLeft = date.difference(DateTime.now()).inDays;
    final eventType = event['event_type'] as String? ?? 'Other';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    _buildChip(theme, _getEventIcon(eventType) + ' ' + eventType),
                    SizedBox(width: 2.w),
                    if (event['dress_code'] != null)
                      _buildChip(theme, event['dress_code']),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysLeft == 0 ? localizations.today + '!' :
                daysLeft == 1 ? localizations.tomorrow : 'In $daysLeft ${localizations.days}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: daysLeft <= 3
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              GestureDetector(
                onTap: () => _deleteEvent(event['id']),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'wedding': return '💍';
      case 'dinner': return '🍽';
      case 'work': return '💼';
      case 'party': return '🎉';
      case 'travel': return '✈️';
      case 'sport': return '⚽';
      default: return '📅';
    }
  }

  // ── CHALLENGES ──────────────────────────────────────────
  Widget _buildChallengesSection(ThemeData theme) {
    final localizations = AppLocalizations.of(context);
    if (_challenges.isEmpty) {
      return _buildEmptyCard(
        theme,
        icon: Icons.flag_outlined,
        title: localizations.noChallengesAvailable,
        subtitle: localizations.checkBackSoon,
      );
    }

    return SizedBox(
      height: 22.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _challenges.length,
        itemBuilder: (context, index) {
          return _buildChallengeCard(theme, _challenges[index]);
        },
      ),
    );
  }

  Widget _buildChallengeCard(ThemeData theme, Map<String, dynamic> challenge) {
    final isJoined = challenge['is_joined'] as bool? ?? false;
    final progress = challenge['progress'] as int? ?? 0;
    final duration = challenge['duration_days'] as int? ?? 7;

    return Container(
      width: 55.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isJoined
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isJoined
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge['category'] as String? ?? 'Style',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$duration days',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            challenge['title'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
          SizedBox(height: 0.5.h),
          Text(
            challenge['description'] as String? ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (isJoined) ...[
            LinearProgressIndicator(
              value: progress / duration,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '$progress/$duration days',
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.colorScheme.primary,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinChallenge(challenge['id']),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppLocalizations.of(context).continueText, style: TextStyle(fontSize: 12.sp)),
              ),
            ),
        ],
      ),
    );
  }

  // ── QUIZ ────────────────────────────────────────────────
  Widget _buildQuizSection(ThemeData theme) {
    final hasResult = _quizResult != null;

    return GestureDetector(
      onTap: hasResult ? null : _startQuiz,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              // Soft pink accent strip
              Container(
                width: 4,
                height: 80,
                color: theme.colorScheme.secondary.withValues(alpha: 0.45),
              ),
              SizedBox(width: 4.w),
              Text(
                hasResult ? '✨' : '🎯',
                style: const TextStyle(fontSize: 36),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.5.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasResult ? localizations.yourStyleProfile : localizations.discoverYourStyle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.4.h),
                      Text(
                        hasResult
                            ? _quizResult!['style_profile'] as String? ?? localizations.completed
                            : localizations.takeQuizToPersonalise,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!hasResult)
                Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: theme.colorScheme.secondary,
                    size: 18,
                  ),
                ),
              if (hasResult)
                TextButton(
                  onPressed: _startQuiz,
                  child: Text(
                    localizations.retake,
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

    // ── COACH ───────────────────────────────────────────────
  Widget _buildCoachSection(ThemeData theme) {
    final nextEvent = _events.isNotEmpty ? _events.first : null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        Text(
                          localizations.tipOfTheWeek,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          _quizResult != null
                              ? _quizResult!['style_profile'] as String? ?? localizations.personalizedCoaching
                              : localizations.completeQuizForCoaching,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _isCoachTipLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        localizations.coachIsThinking,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _coachTip.isNotEmpty ? _coachTip : localizations.coachIsPreparingTip,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCoachPromptSheet,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(AppLocalizations.of(context).askYourCoach),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.4.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildCoachMiniCard(
                theme,
                icon: Icons.question_answer_outlined,
                title: localizations.quickQuestions,
                subtitle: localizations.getHelpStylingPieces,
                onTap: _showCoachPromptSheet,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildCoachMiniCard(
                theme,
                icon: Icons.event_available,
                title: localizations.eventCoaching,
                subtitle: nextEvent != null
                    ? localizations.suggestionsFor(nextEvent['title'] as String)
                    : localizations.addEventToUnlock,
                onTap: nextEvent != null
                    ? () => _showEventCoachDialog(nextEvent)
                    : _showAddEventDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoachMiniCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 24),
            SizedBox(height: 1.2.h),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCoachPromptSheet() async {
    final user = _styleService.client.auth.currentUser;
    if (user == null) return;

    // ── TIER CHECK ─────────────────────────────────────────
    final canUse = await _tierService.canUseCoach(user.id);
    if (!canUse) {
      if (!mounted) return;
      UpgradePromptWidget.show(
        context,
        title: localizations.coachLimitReached,
        message: _isPremium
            ? localizations.premiumCoachLimitMsg
            : localizations.freeCoachLimitMsg,
      );
      return;
    }

    // ── SHOW SHEET ─────────────────────────────────────────
    final topics = [
      {'label': localizations.topicOutfitIdeas, 'question': localizations.qOutfitIdeas},
      {'label': localizations.topicShoppingAdvice, 'question': localizations.qShoppingAdvice},
      {'label': localizations.topicMyWardrobe, 'question': localizations.qMyWardrobe},
      {'label': localizations.topicForAnEvent, 'question': localizations.qForAnEvent},
      {'label': localizations.topicMoreVariety, 'question': localizations.qMoreVariety},
      {'label': localizations.topicStyleUpgrade, 'question': localizations.qStyleUpgrade},
    ];

    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.askYourCoach,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show quota badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: (_coachingQuota['remaining'] as int) > 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_coachingQuota['remaining'] as int) > 0
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          '${_coachingQuota['remaining']}/${_coachingQuota['limit']} ${_coachingQuota['period']}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: (_coachingQuota['remaining'] as int) > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    localizations.typeQuestionOrPickTopic,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customController,
                          decoration: InputDecoration(
                            hintText: localizations.coachHintText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.5.h,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (val) {
                            if (val.trim().isEmpty) return;
                            Navigator.pop(context);
                            _askCoachQuestion(val.trim());
                          },
                        ),
                      ),
                      SizedBox(width: 2.w),
                      IconButton(
                        onPressed: () {
                          final val = customController.text.trim();
                          if (val.isEmpty) return;
                          Navigator.pop(context);
                          _askCoachQuestion(val);
                        },
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    localizations.orPickATopic,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: topics.map((topic) => ActionChip(
                      label: Text(topic['label']!),
                      onPressed: () {
                        Navigator.pop(context);
                        _askCoachQuestion(topic['question']!);
                      },
                    )).toList(),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEventCoachDialog(Map<String, dynamic> event) {
    final date = DateTime.parse(event['event_date']);
    final dateStr = DateFormat('MMM dd').format(date);
    final eventType = event['event_type'] as String? ?? 'Other';
    final dressCode = event['dress_code'] as String?;
    bool isLoading = true;
    Map<String, dynamic> coachData = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Trigger load only once
          if (isLoading && coachData.isEmpty) {
            isLoading = false; // prevent re-trigger
            _styleService.fetchEventCoaching(
              event: event,
              insights: _insights,
              quizResult: _quizResult,
            ).then((data) {
              if (context.mounted) {
                setDialogState(() {
                  coachData = data;
                });
              }
            });
          }

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event['title'] as String),
                Text(
                  '$dateStr · $eventType${dressCode != null ? " · $dressCode" : ""}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : coachData.containsKey('error')
                  ? Text(coachData['error'] as String)
                  : SingleChildScrollView(
                      child: Builder(
                        builder: (ctx) {
                          final dlgTheme = Theme.of(ctx);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (coachData['intro'] != null) ...[
                                Text(coachData['intro'] as String),
                                const SizedBox(height: 12),
                              ],
                              if (coachData['outfit_1'] != null)
                                _buildOutfitSuggestion(dlgTheme, '1', coachData['outfit_1'] as String),
                              if (coachData['outfit_2'] != null)
                                _buildOutfitSuggestion(dlgTheme, '2', coachData['outfit_2'] as String),
                              if (coachData['outfit_3'] != null)
                                _buildOutfitSuggestion(dlgTheme, '3', coachData['outfit_3'] as String),
                              if (coachData['prep_tip'] != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('💡 ', style: TextStyle(fontSize: 14)),
                                      Expanded(child: Text(coachData['prep_tip'] as String,
                                        style: const TextStyle(fontSize: 13))),
                                    ],
                                  ),
                                ),
                              ],
                              if (coachData['tip'] != null)
                                Text(coachData['tip'] as String),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).done),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOutfitSuggestion(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(number, style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  void _askCoachQuestion(String question) async {
    final user = _styleService.client.auth.currentUser;

    // Increment coaching count
    if (user != null) {
      await _tierService.incrementCoachingCount(user.id);
      final quota = await _tierService.getCoachingQuota(user.id);
      if (mounted) setState(() => _coachingQuota = quota);
    }

    bool isLoading = true;
    Map<String, dynamic> result = {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoading && result.isEmpty) {
            isLoading = false; // prevent re-trigger
            _styleService.askCoach(
              question: question,
              insights: _insights,
              quizResult: _quizResult,
            ).then((data) {
              if (context.mounted) {
                setDialogState(() {
                  result = data;
                });
              }
            });
          }

          return AlertDialog(
            title: Text(AppLocalizations.of(context).styleCoach),
            content: SizedBox(
              width: double.maxFinite,
              child: isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          question,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result['answer'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if ((result['next_step'] as String? ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('👣 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    result['next_step'] as String,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).done),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── INSIGHTS ────────────────────────────────────────────
  Widget _buildInsightsSection(ThemeData theme) {
    if (_insights['totalItems'] == 0) {
      return _buildEmptyCard(
        theme,
        icon: Icons.insights_outlined,
        title: localizations.noInsightsYet,
        subtitle: localizations.addItemsForInsights,
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '👗',
                label: localizations.totalItemsLabel,
                value: '${_insights['totalItems']}',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '📊',
                label: localizations.outfitsLoggedLabel,
                value: '${_insights['totalOutfitsLogged']}',
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '🏆',
                label: localizations.topCategoryLabel,
                value: '${_insights['topCategory']}',
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: '🎯',
                label: localizations.topOccasionLabel,
                value: '${_insights['topOccasion']}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(ThemeData theme, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon,
      {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 2.w),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          SizedBox(height: 1.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  // ── ACTIONS ─────────────────────────────────────────────
  void _showAddEventDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedType = 'Dinner';
    String? dressCode;

    final eventTypes = ['Wedding', 'Dinner', 'Work', 'Party', 'Travel', 'Sport', 'Other'];
    final dressCodes = ['Casual', 'Smart Casual', 'Formal', 'Black Tie', 'Sporty'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(AppLocalizations.of(context).addEvent,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 2.h),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: localizations.eventName,
                    hintText: localizations.hintWedding,
                    prefixIcon: const Icon(Icons.event),
                  ),
                ),
                SizedBox(height: 2.h),
                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: localizations.dateLabel,
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('MMM dd, yyyy').format(selectedDate),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                // Event type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: eventTypes.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setSheetState(() => selectedType = v!),
                ),
                SizedBox(height: 2.h),
                // Dress code
                DropdownButtonFormField<String>(
                  value: dressCode,
                  decoration: InputDecoration(
                    labelText: localizations.dressCodeOptional,
                    prefixIcon: const Icon(Icons.checkroom),
                  ),
                  items: dressCodes.map((d) =>
                    DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setSheetState(() => dressCode = v),
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      final result = await _styleService.addEvent(
                        title: titleController.text.trim(),
                        eventDate: selectedDate,
                        eventType: selectedType,
                        dressCode: dressCode,
                      );
                      if (result != null) _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context).addEvent),
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteEvent),
        content: Text(AppLocalizations.of(context).removeEventQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _styleService.deleteEvent(eventId);
      _loadData();
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    final success = await _styleService.joinChallenge(challengeId);
    if (success) _loadData();
  }

  void _startQuiz() {
    _showQuizDialog();
  }

  void _showQuizDialog() {
        final questions = [
      {
        'question': 'Which outfits make you feel most like yourself?',
        'options': [
          'Relaxed and effortless',
          'Polished and timeless',
          'Creative and expressive',
          'Practical and sporty',
        ],
      },
      {
        'question': 'What colors dominate your wardrobe today?',
        'options': [
          'Mostly neutrals',
          'Earth tones and warm shades',
          'Bold colors and contrast',
          'Soft tones and light shades',
        ],
      },
      {
        'question': 'What do you want help with most right now?',
        'options': [
          'Looking more put together',
          'Creating more outfit variety',
          'Shopping more intentionally',
          'Feeling more confident in what I wear',
        ],
      },
      {
        'question': localizations.qStyleAdventures,
        'options': [
          localizations.qStyleAdventurousWorks,
          localizations.qStyleAdventurousSmall,
          localizations.qStyleAdventurousOften,
          localizations.qStyleAdventurousDepends,
        ],
      },
      {
        'question': 'When choosing clothes, what matters most to you?',
        'options': [
          'Comfort',
          'Elegance',
          'Originality',
          'Versatility',
        ],
      },
    ];

    int currentQuestion = 0;
    final Map<String, String> answers = {};
    final intentionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final q = questions[currentQuestion];
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.styleQuiz} ${currentQuestion + 1}/${questions.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                LinearProgressIndicator(
                  value: (currentQuestion + 1) / questions.length,
                ),
                const SizedBox(height: 8),
                Text(q['question'] as String),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: (q['options'] as List<String>).map((option) =>
                ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: answers[q['question']],
                    onChanged: (v) => setDialogState(() => answers[q['question'] as String] = v!),
                  ),
                  onTap: () => setDialogState(() => answers[q['question'] as String] = option),
                ),
              ).toList(),
            ),
            actions: [
              if (currentQuestion > 0)
                TextButton(
                  onPressed: () => setDialogState(() => currentQuestion--),
                  child: Text(AppLocalizations.of(context).back),
                ),
              ElevatedButton(
                onPressed: answers[q['question']] == null ? null : () async {
                  if (currentQuestion < questions.length - 1) {
                    setDialogState(() => currentQuestion++);
                  } else if (currentQuestion == questions.length - 1) {
                    setDialogState(() => currentQuestion++); // go to intention step
                  } else {
                    Navigator.pop(context);
                    final profile = _determineStyleProfile(answers);
                    await _styleService.saveQuizResult(
                      styleProfile: profile,
                      preferredColors: [answers[questions[1]['question']] ?? ''],
                      styleGoals: [answers[questions[2]['question']] ?? ''],
                      answers: answers,
                      styleIntention: intentionController.text.trim(),
                    );
                    _loadData();
                  }
                },
                child: Text(currentQuestion < questions.length - 1 ? localizations.next : localizations.finish),
              ),
            ],
          );
        },
      ),
    );
  }

  String _determineStyleProfile(Map<String, String> answers) {
    final style = answers.values.join(' ').toLowerCase();

    if (style.contains('polished') ||
        style.contains('timeless') ||
        style.contains('elegance')) {
      return 'Classic Elegance';
    }

    if (style.contains('creative') ||
        style.contains('expressive') ||
        style.contains('experiment')) {
      return 'Bold & Trendy';
    }

    if (style.contains('sporty') ||
        style.contains('practical')) {
      return 'Active & Sporty';
    }

    if (style.contains('versatility') ||
        style.contains('small changes') ||
        style.contains('what i know works')) {
      return 'Minimalist';
    }

    return 'Casual Chic';
  }
}
