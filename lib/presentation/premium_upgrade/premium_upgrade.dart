import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/subscription_service.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';
import './widgets/faq_item_widget.dart';
import './widgets/feature_comparison_widget.dart';
import './widgets/hero_section_widget.dart';
import './widgets/pricing_card_widget.dart';
import './widgets/testimonial_widget.dart';

class PremiumUpgrade extends StatefulWidget {
  const PremiumUpgrade({Key? key}) : super(key: key);

  @override
  State<PremiumUpgrade> createState() => _PremiumUpgradeState();
}

class _PremiumUpgradeState extends State<PremiumUpgrade> {
  String _selectedPlan = 'yearly';
  final _subscriptionService = SubscriptionService();

  final List<Map<String, dynamic>> _testimonials = [
    {
      'name': 'Sarah Chen',
      'image': 'assets/images/testimonials/sarah_chen.png',
      'text':
          'Premium analytics helped me reduce impulse purchases and get more value from the clothes I already own.',
      'rating': 5,
    },
    {
      'name': 'Marcus Johnson',
      'image': 'assets/images/testimonials/marcus_johnson.png',
      'text':
          'The AI suggestions and outfit variations made the app feel like a real personal stylist.',
      'rating': 5,
    },
    {
      'name': 'Emma Rodriguez',
      'image': 'assets/images/testimonials/emma_rodriguez.png',
      'text':
          'Premium made the app much more useful day to day. More ideas, more guidance, no ads.',
      'rating': 5,
    },
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Can I cancel anytime?',
      'answer':
          'Yes. Your subscription renews automatically, and you can cancel anytime from your Play Store or App Store subscription settings.',
    },
    {
      'question': 'What happens if I cancel?',
      'answer':
          'You will keep Premium access until the end of the current billing period, then your account will return to the free plan.',
    },
    {
      'question': 'Can I restore my subscription?',
      'answer':
          'Yes. If you already purchased Premium on this account, you can restore your purchases at any time.',
    },
    {
      'question': 'Do you offer discount codes?',
      'answer':
          'Occasionally, yes. Special discount codes may be shared through campaigns, partnerships, or selected creators.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Premium Upgrade',
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeroSectionWidget(),

            SizedBox(height: 3.h),

            const FeatureComparisonWidget(),

            SizedBox(height: 4.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 1.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Text(
                'Upgrade when you want more suggestions, more coaching, more outfit variations, and no ads.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 3.h),

            PricingCardWidget(
              planName: 'Monthly',
              price: '€7.49',
              period: '/month',
              features: const [
                'More AI outfit suggestions',
                'More coach interactions',
                'More event outfit generations',
                'Ad-free experience',
                'Access to Premium features while subscribed',
              ],
              isSelected: _selectedPlan == 'monthly',
              onSelect: () => setState(() => _selectedPlan = 'monthly'),
              onUpgrade: _handleUpgrade,
            ),

            SizedBox(height: 2.h),

            PricingCardWidget(
              planName: 'Yearly',
              price: '€69.90',
              period: '/year',
              savings: '-22%',
              features: const [
                'Everything in Monthly',
                'Better yearly value',
                'Fewer renewals to manage',
                'Full Premium access all year',
                'Best plan for regular users',
              ],
              isSelected: _selectedPlan == 'yearly',
              isBestValue: true,
              onSelect: () => setState(() => _selectedPlan = 'yearly'),
              onUpgrade: _handleUpgrade,
            ),

            SizedBox(height: 3.h),

            _buildStoreInfoCard(theme),

            SizedBox(height: 4.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'What Our Users Say',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            SizedBox(
              height: 20.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _testimonials.length,
                itemBuilder: (context, index) {
                  return TestimonialWidget(
                    name: _testimonials[index]['name'],
                    image: _testimonials[index]['image'],
                    text: _testimonials[index]['text'],
                    rating: _testimonials[index]['rating'],
                  );
                },
              ),
            ),

            SizedBox(height: 4.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            SizedBox(height: 2.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: _faqs
                    .map(
                      (faq) => FaqItemWidget(
                        question: faq['question'],
                        answer: faq['answer'],
                      ),
                    )
                    .toList(),
              ),
            ),

            SizedBox(height: 3.h),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(3.5.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: theme.colorScheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Store Billing',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Subscriptions are handled securely through Google Play or the App Store on your device.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            Center(
              child: TextButton(
                onPressed: _handleRestorePurchases,
                child: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfoCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How billing works',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  'Your subscription will be managed by Google Play or the App Store. No card form is required here — billing continues through your store account.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorDialog('Please login to continue');
      return;
    }
    try {
      final offerings = await _subscriptionService.getOfferings();
      if (offerings == null || offerings.current == null) {
        _showErrorDialog('No offerings available. Please try again later.');
        return;
      }
      final packages = offerings.current!.availablePackages;
      Package? selectedPackage;
      if (_selectedPlan == 'yearly') {
        selectedPackage = packages.firstWhere(
          (p) => p.packageType == PackageType.annual,
          orElse: () => packages.first,
        );
      } else {
        selectedPackage = packages.firstWhere(
          (p) => p.packageType == PackageType.monthly,
          orElse: () => packages.first,
        );
      }
      final success = await _subscriptionService.purchase(selectedPackage);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Signature!')),
        );
        Navigator.pop(context);
      }
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        _showErrorDialog('Purchase failed: ${e.name}');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _handleRestorePurchases() async {
    try {
      final hasAccess = await _subscriptionService.restorePurchases();
      if (!mounted) return;
      if (hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!')),
        );
        Navigator.pop(context);
      } else {
        _showErrorDialog('No active subscription found to restore.');
      }
    } catch (e) {
      _showErrorDialog('Restore failed: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
