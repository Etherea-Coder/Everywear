import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  String _selectedType = 'Suggestion';
  int _selectedRating = 0;

  final List<String> _feedbackTypes = [
    'Suggestion',
    'Bug',
    'Design',
    'AI suggestions',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _prefillEmail();
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Send Feedback',
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(theme),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'What would you like to share?',
                icon: Icons.chat_bubble_outline,
                child: _buildTypeSelectorCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'Your message',
                icon: Icons.edit_outlined,
                child: _buildMessageCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'How is your experience so far?',
                icon: Icons.star_outline,
                child: _buildRatingCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'Contact email',
                icon: Icons.mail_outline,
                child: _buildEmailCard(theme),
              ),
              SizedBox(height: 2.h),

              _buildSection(
                theme,
                title: 'A quick note',
                icon: Icons.info_outline,
                child: _buildInfoCard(theme),
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
                    label: Text(_isSubmitting ? 'Sending...' : 'Send Feedback'),
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

  Widget _buildHeroCard(ThemeData theme) {
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
                  'We would love to hear from you',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Your ideas, bug reports, and reflections help shape Everywear into a more thoughtful wardrobe studio.',
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

  Widget _buildTypeSelectorCard(ThemeData theme) {
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
        children: _feedbackTypes.map((type) {
          final selected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
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
                type,
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

  Widget _buildMessageCard(ThemeData theme) {
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
        decoration: const InputDecoration(
          hintText:
              'Tell us what happened, what you would improve, or what you would love to see next...',
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please write a message';
          }
          if (value.trim().length < 8) {
            return 'Please add a little more detail';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRatingCard(ThemeData theme) {
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
            'Optional, but helpful',
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

  Widget _buildEmailCard(ThemeData theme) {
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
        decoration: const InputDecoration(
          hintText: 'your@email.com',
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
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
        'If you report a bug, a few details like where it happened, what you expected, and what happened instead will help a lot.',
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
      // Replace this block later with your real insert / email / edge function.
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you — your feedback has been sent'),
        ),
      );

      _messageController.clear();
      setState(() {
        _selectedType = 'Suggestion';
        _selectedRating = 0;
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send feedback: $e'),
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
