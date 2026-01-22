import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../widgets/custom_app_bar.dart';
import '../../services/payment_service.dart';
import '../../services/user_tier_service.dart';
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
  String _selectedPlan = 'annual';
  bool _isProcessingPayment = false;
  bool _showPaymentSheet = false;

  // Controllers for billing form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _testimonials = [
    {
      'name': 'Sarah Chen',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1559df74b-1766991425900.png',
      'text':
          'Premium analytics helped me reduce impulse purchases by 60%. The AI suggestions are spot-on!',
      'rating': 5,
    },
    {
      'name': 'Marcus Johnson',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_196e48b77-1764865098990.png',
      'text':
          'The detailed cost-per-wear tracking changed how I shop. Worth every penny.',
      'rating': 5,
    },
    {
      'name': 'Emma Rodriguez',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1852c4b53-1768226787988.png',
      'text':
          'Learning modules taught me sustainable fashion practices I use daily.',
      'rating': 5,
    },
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Can I cancel anytime?',
      'answer':
          'Yes! Cancel anytime from your account settings. No questions asked, no hidden fees.',
    },
    {
      'question': 'What happens to my data if I downgrade?',
      'answer':
          'Your data is never deleted. You\'ll retain access to all logged outfits, but premium analytics will be limited.',
    },
    {
      'question': 'Is the 7-day trial really free?',
      'answer':
          'Absolutely! No credit card required for the trial. You\'ll only be charged if you continue after 7 days.',
    },
    {
      'question': 'Can I share my subscription with family?',
      'answer':
          'Yes! Premium plans support family sharing on both iOS and Android platforms.',
    },
    {
      'question': 'Do you offer student discounts?',
      'answer':
          'Yes! Students get 30% off annual plans. Contact support with your student ID for verification.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
        _nameController.text = user.userMetadata?['full_name'] ?? '';
      });
    }
  }

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
            // Hero Section
            const HeroSectionWidget(),

            SizedBox(height: 3.h),

            // Feature Comparison
            const FeatureComparisonWidget(),

            SizedBox(height: 4.h),

            // Pricing Plans
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
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Start with a 7-day free trial',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 3.h),

            // Monthly Plan
            PricingCardWidget(
              planName: 'Monthly',
              price: '\$9.99',
              period: '/month',
              features: [
                'Unlimited outfit logging',
                'Advanced AI suggestions',
                'Detailed analytics dashboard',
                'Exclusive learning modules',
                'Priority customer support',
              ],
              isSelected: _selectedPlan == 'monthly',
              onSelect: () => setState(() => _selectedPlan = 'monthly'),
              onUpgrade: _handleUpgrade,
            ),

            SizedBox(height: 2.h),

            // Annual Plan (Best Value)
            PricingCardWidget(
              planName: 'Annual',
              price: '\$99.99',
              period: '/year',
              savings: 'Save \$20',
              features: [
                'Everything in Monthly',
                'Family sharing (up to 5 members)',
                'Early access to new features',
                'Personalized style coaching',
                'Annual sustainability report',
              ],
              isSelected: _selectedPlan == 'annual',
              isBestValue: true,
              onSelect: () => setState(() => _selectedPlan = 'annual'),
              onUpgrade: _handleUpgrade,
            ),

            SizedBox(height: 4.h),

            // Testimonials
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

            // FAQ Section
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

            // Risk-Free Guarantee
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: theme.colorScheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Risk-Free Guarantee',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Try premium features for 7 days. Cancel anytime with full refund if not satisfied.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Restore Purchases
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

            // Payment Sheet Dialog
            if (_showPaymentSheet) _buildPaymentSheet(theme),
          ],
        ),
      ),
      bottomNavigationBar: _isProcessingPayment
          ? Container(
              padding: EdgeInsets.all(2.h),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          : Container(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPlan == 'annual'
                                    ? 'Annual Plan'
                                    : 'Monthly Plan',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                _selectedPlan == 'annual'
                                    ? '\$99.99/year'
                                    : '\$9.99/month',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _handleUpgrade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Continue to Payment',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '7-day free trial • Cancel anytime',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentSheet(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _showPaymentSheet = false);
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            Text(
              'Card Information',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(3.w),
              child: stripe.CardField(
                onCardChanged: (card) {
                  // Card validation handled by CardField
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  helperText: 'Enter your card details',
                ),
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Pay ${_selectedPlan == 'annual' ? '\$99.99' : '\$9.99'}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorDialog('Please login to continue');
      return;
    }

    setState(() => _showPaymentSheet = true);
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final amount = _selectedPlan == 'annual' ? 99.99 : 9.99;

      final paymentIntentResponse = await PaymentService.instance
          .createPaymentIntent(
            amount: amount,
            userId: user.id,
            planType: _selectedPlan,
            currency: 'usd',
          );

      final billingDetails = stripe.BillingDetails(
        name: _nameController.text,
        email: _emailController.text,
        address: stripe.Address(
          line1: '',
          line2: '',
          city: '',
          state: '',
          postalCode: '',
          country: 'US',
        ),
      );

      final result = await PaymentService.instance.processPayment(
        clientSecret: paymentIntentResponse.clientSecret,
        billingDetails: billingDetails,
      );

      if (result.success) {
        final upgraded = await UserTierService().upgradeToPremium(user.id);
        if (upgraded) {
          _showSuccessDialog();
        } else {
          throw Exception('Failed to upgrade account');
        }
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isProcessingPayment = false;
        _showPaymentSheet = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              const Text('Welcome to Premium!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your payment was successful! You now have access to all premium features.',
              ),
              SizedBox(height: 2.h),
              Text(
                'Plan: ${_selectedPlan == 'annual' ? 'Annual' : 'Monthly'}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
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

  void _handleRestorePurchases() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for previous purchases...')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
