import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_localizations.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedTypeKey;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _prefillEmail();
    _selectedTypeKey = 'suggestion';
  }

  void _prefillEmail() {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final Map<String, String> feedbackTypes = {
      'suggestion': l10n.feedbackTypeSuggestion,
      'bug': l10n.feedbackTypeBug,
      'design': l10n.feedbackTypeDesign,
      'ai_suggestions': l10n.feedbackTypeAiSuggestions,
      'other': l10n.feedbackTypeOther,
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: l10n.sendFeedback,
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(theme, l10n),
              SizedBox(height: 2.h),
              _buildSection(
                theme,
                title: l10n.feedbackTypeSectionTitle,
                icon: Icons.chat_bubble_outline,
                child: _buildTypeSelectorCard(theme, feedbackTypes),
              ),
              SizedBox(height: 2.h),
              _buildSection(
                theme,
                title: l10n.feedbackMessageSectionTitle,
                icon: Icons.edit_outlined,
                child: _buildMessageCard(theme, l10n),
              ),
              SizedBox(height: 2.h),
              _buildSection(
                theme,
                title: l10n.feedbackExperienceSectionTitle,
                icon: Icons.star_outline,
                child: _buildRatingCard(theme, l10n),
              ),
              SizedBox(height: 2.h),
              _buildSection(
                theme,
                title: l10n.feedbackEmailSectionTitle,
                icon: Icons.mail_outline,
                child: _buildEmailCard(theme, l10n),
              ),
              SizedBox(height: 2.h),
              _buildSection(
                theme,
                title: l10n.feedbackNoteSectionTitle,
                icon: Icons.info_outline,
                child: _buildInfoCard(theme, l10n),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_isSubmitting
                        ? l10n.feedbackSending
                        : l10n.sendFeedback),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.16),
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.forum_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.feedbackHeroTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  l10n.feedbackHeroSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildTypeSelectorCard(
    ThemeData theme,
    Map<String, String> feedbackTypes,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.2.h,
        children: feedbackTypes.entries.map((entry) {
          final selected = _selectedTypeKey == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedTypeKey = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.35)
                      : theme.colorScheme.outline.withValues(alpha: 0.20),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                entry.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.88),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _messageController,
        maxLines: 7,
        decoration: InputDecoration(
          hintText: l10n.feedbackMessageHint,
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.feedbackMessageRequired;
          }
          if (value.trim().length < 8) {
            return l10n.feedbackMessageTooShort;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRatingCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feedbackRatingOptional,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.2.h),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final selected = _selectedRating >= starIndex;
              return Padding(
                padding: EdgeInsets.only(right: 1.w),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRating = starIndex),
                  child: Icon(
                    selected ? Icons.star : Icons.star_border,
                    color: selected
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: l10n.feedbackEmailHint,
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          if (!value.contains('@')) {
            return l10n.feedbackEmailInvalid;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        l10n.feedbackNoteText,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final l10n = AppLocalizations.of(context);
      final feedbackTypes = {
        'suggestion': l10n.feedbackTypeSuggestion,
        'bug': l10n.feedbackTypeBug,
        'design': l10n.feedbackTypeDesign,
        'ai_suggestions': l10n.feedbackTypeAiSuggestions,
        'other': l10n.feedbackTypeOther,
      };

      final success = await _profileService.submitFeedback(
        type: feedbackTypes[_selectedTypeKey] ?? _selectedTypeKey!,
        message: _messageController.text.trim(),
        rating: _selectedRating > 0 ? _selectedRating : null,
      );
      if (!success) throw Exception('Failed to save feedback');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackSuccessMessage),
        ),
      );

      _messageController.clear();
      setState(() {
        _selectedTypeKey = 'suggestion';
        _selectedRating = 0;
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackErrorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}