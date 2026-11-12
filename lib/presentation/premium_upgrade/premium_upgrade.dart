import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/subscription_service.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/providers.dart';
import './widgets/faq_item_widget.dart';
import './widgets/feature_comparison_widget.dart';
import './widgets/hero_section_widget.dart';
import './widgets/pricing_card_widget.dart';
import '../../services/revenuecat_service.dart';
import '../../services/revenuecat_web_checkout.dart';

class PremiumUpgrade extends ConsumerStatefulWidget {
  const PremiumUpgrade({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumUpgrade> createState() => _PremiumUpgradeState();
}

class _PremiumUpgradeState extends ConsumerState<PremiumUpgrade> {
  String _selectedPlan = 'yearly';
  final _subscriptionService = SubscriptionService();
  final _billingConfig = RevenueCatWebCheckoutConfig.fromEnvironment();
  Offerings? _offerings;
  bool _storeReady = false;

  @override
  void initState() {
    super.initState();
    if (_billingConfig.distribution == AppDistribution.googlePlay) {
      _loadOfferings();
    }
  }

  Future<void> _loadOfferings() async {
    final offerings = await _subscriptionService.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _storeReady =
          RevenueCatService.isConfigured && offerings?.current != null;
    });
  }

  Package? _package(PackageType type) {
    final packages =
        _offerings?.current?.availablePackages ?? const <Package>[];
    for (final package in packages) {
      if (package.packageType == type) return package;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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

            if (_billingConfig.distribution == AppDistribution.googlePlay) ...[
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
                price:
                    _package(PackageType.monthly)?.storeProduct.priceString ??
                    '—',
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
                enabled: _storeReady && _package(PackageType.monthly) != null,
              ),

              SizedBox(height: 2.h),

              PricingCardWidget(
                planName: l10n.yearly,
                price:
                    _package(PackageType.annual)?.storeProduct.priceString ??
                    '—',
                period: l10n.perYear,
                features: [
                  l10n.everythingInMonthly,
                  l10n.betterYearlyValue,
                  l10n.fewerRenewals,
                  l10n.fullPremiumAllYear,
                  l10n.bestPlanRegularUsers,
                ],
                isSelected: _selectedPlan == 'yearly',
                onSelect: () => setState(() => _selectedPlan = 'yearly'),
                onUpgrade: _handleUpgrade,
                enabled: _storeReady && _package(PackageType.annual) != null,
              ),

              SizedBox(height: 3.h),

              _buildStoreInfoCard(theme, l10n),

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
            ] else ...[
              _buildHostedBillingCard(theme, l10n),
            ],

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
          ],
        ),
      ),
    );
  }

  Widget _buildHostedBillingCard(ThemeData theme, AppLocalizations l10n) {
    final ready =
        _billingConfig.isAvailable &&
        RevenueCatService.isConfigured &&
        SupabaseService.isInitialized;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.hostedCheckoutTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.6.h),
          Text(
            ready
                ? l10n.hostedCheckoutDescription
                : l10n.hostedCheckoutUnavailable,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (ready) ...[
            SizedBox(height: 1.6.h),
            FilledButton(
              onPressed: _handleHostedCheckout,
              child: Text(l10n.continueToCheckout),
            ),
          ],
          if (RevenueCatService.isConfigured &&
              _billingConfig.distribution == AppDistribution.uptodown) ...[
            SizedBox(height: 0.8.h),
            TextButton(
              onPressed: _handleManageSubscription,
              child: Text(l10n.manageSubscription),
            ),
            TextButton(
              onPressed: _handleRefreshWebSubscription,
              child: Text(l10n.refreshSubscriptionStatus),
            ),
          ],
        ],
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
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 22),
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
      final offerings = _offerings;
      if (offerings == null || offerings.current == null) {
        _showErrorDialog(l10n.noOfferingsAvailable);
        return;
      }
      final selectedPackage = _package(
        _selectedPlan == 'yearly' ? PackageType.annual : PackageType.monthly,
      );
      if (selectedPackage == null) {
        _showErrorDialog(l10n.noOfferingsAvailable);
        return;
      }
      final result = await _subscriptionService.purchase(selectedPackage);
      if (result.isSuccess && mounted) {
        ref.invalidate(userTierProvider);
        ref.invalidate(userProfileProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.welcomeToSignature)));
        Navigator.pop(context);
      } else if (mounted &&
          result.status != SubscriptionActionStatus.cancelled) {
        _showErrorDialog(result.message ?? l10n.purchaseFailed);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _handleHostedCheckout() async {
    final l10n = AppLocalizations.of(context);
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorDialog(l10n.pleaseLoginContinue);
      return;
    }
    final result = await _subscriptionService.startHostedCheckout();
    if (!mounted) return;
    if (result.status == SubscriptionActionStatus.checkoutOpened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.hostedCheckoutOpened)));
    } else {
      _showErrorDialog(l10n.hostedCheckoutUnavailable);
    }
  }

  Future<void> _handleManageSubscription() async {
    final opened = await _subscriptionService.openSubscriptionManagement();
    if (!mounted) return;
    if (!opened) {
      _showErrorDialog(
        AppLocalizations.of(context).subscriptionManagementUnavailable,
      );
    }
  }

  Future<void> _handleRefreshWebSubscription() async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showErrorDialog(AppLocalizations.of(context).pleaseLoginContinue);
      return;
    }
    final result = await _subscriptionService.verifyHostedCheckoutReturn(
      userId,
    );
    if (!mounted) return;
    ref.invalidate(userTierProvider);
    ref.invalidate(userProfileProvider);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.subscriptionStatusVerified
              : l10n.subscriptionNotVerified,
        ),
      ),
    );
  }

  Future<void> _handleRestorePurchases() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await _subscriptionService.restorePurchases();
      if (!mounted) return;
      if (result.isSuccess) {
        ref.invalidate(userTierProvider);
        ref.invalidate(userProfileProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.purchasesRestoredSuccess)));
        Navigator.pop(context);
      } else {
        _showErrorDialog(result.message ?? l10n.noActiveSubscriptionRestore);
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
