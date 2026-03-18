import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/subscription_service.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';
import '../../core/utils/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final List<Map<String, dynamic>> _testimonials = [
      {
        'name': 'Sarah Chen',
        'image': 'assets/images/testimonials/sarah_chen.png',
        'text': l10n.testimonialSarahText,
        'rating': 5,
      },
      {
        'name': 'Marcus Johnson',
        'image': 'assets/images/testimonials/marcus_johnson.png',
        'text': l10n.testimonialMarcusText,
        'rating': 5,
      },
      {
        'name': 'Emma Rodriguez',
        'image': 'assets/images/testimonials/emma_rodriguez.png',
        'text': l10n.testimonialEmmaText,
        'rating': 5,
      },
    ];

    final List<Map<String, dynamic>> _faqs = [
      {
        'question': l10n.faqCancelAnytime,
        'answer': l10n.faqCancelAnytimeAnswer,
      },
      {
        'question': l10n.faqWhatHappensCancel,
        'answer': l10n.faqWhatHappensCancelAnswer,
      },
      {
        'question': l10n.faqRestoreSubscription,
        'answer': l10n.faqRestoreSubscriptionAnswer,
      },
      {
        'question': l10n.faqDiscountCodes,
        'answer': l10n.faqDiscountCodesAnswer,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: l10n.premiumUpgrade,
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
                l10n.chooseYourPlan,
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
                l10n.upgradeMoreFeatures,
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
              planName: l10n.monthly,
              price: '€7.49',
              period: l10n.perMonth,
              features: [
                l10n.moreAiOutfitSuggestions,
                l10n.moreCoachInteractions,
                l10n.moreEventOutfitGenerations,
                l10n.adFreeExperience,
                l10n.accessPremiumWhileSubscribed,
              ],
              isSelected: _selectedPlan == 'monthly',
              onSelect: () => setState(() => _selectedPlan = 'monthly'),
              onUpgrade: _handleUpgrade,
            ),

            SizedBox(height: 2.h),

            PricingCardWidget(
              planName: l10n.yearly,
              price: '€69.90',
              period: l10n.perYear,
              savings: l10n.savePercent,
              features: [
                l10n.everythingInMonthly,
                l10n.betterYearlyValue,
                l10n.fewerRenewals,
                l10n.fullPremiumAllYear,
                l10n.bestPlanRegularUsers,
              ],
              isSelected: _selectedPlan == 'yearly',
              isBestValue: true,
              onSelect: () => setState(() => _selectedPlan = 'yearly'),
              onUpgrade: _handleUpgrade,
            ),

            SizedBox(height: 3.h),

            _buildStoreInfoCard(theme, l10n),

            SizedBox(height: 4.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                l10n.whatUsersSay,
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
                l10n.frequentlyAskedQuestions,
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
                          l10n.secureStoreBilling,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          l10n.subscriptionsHandledSecurely,
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
                  l10n.restorePurchases,
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

  Widget _buildStoreInfoCard(ThemeData theme, AppLocalizations l10n) {
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
                  l10n.howBillingWorks,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  l10n.billingManagedByStore,
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
    final l10n = AppLocalizations.of(context);
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorDialog(l10n.pleaseLoginContinue);
      return;
    }
    try {
      final offerings = await _subscriptionService.getOfferings();
      if (offerings == null || offerings.current == null) {
        _showErrorDialog(l10n.noOfferingsAvailable);
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
          SnackBar(content: Text(l10n.welcomeToSignature)),
        );
        Navigator.pop(context);
      }
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        _showErrorDialog('${l10n.purchaseFailed}: ${e.name}');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _handleRestorePurchases() async {
    final l10n = AppLocalizations.of(context);
    try {
      final hasAccess = await _subscriptionService.restorePurchases();
      if (!mounted) return;
      if (hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchasesRestoredSuccess)),
        );
        Navigator.pop(context);
      } else {
        _showErrorDialog(l10n.noActiveSubscriptionRestore);
      }
    } catch (e) {
      _showErrorDialog('${l10n.restoreFailed}: ${e.toString()}');
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