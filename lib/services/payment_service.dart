import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  // ignore: unused_field
  final Dio _dio = Dio();
  // ignore: unused_field
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';

  /// Initialize Payment Service
  static Future<void> initialize() async {
    // Stripe initialization removed
    if (kDebugMode) {
      print('Payment Service initialized (Stripe removed)');
    }
  }

  /// Create payment intent for subscription (Placeholder for Play Store)
  Future<PaymentResult> startPlayStorePurchase({
    required double amount,
    required String userId,
    required String planType,
  }) async {
    // This will be replaced with Google Play Billing logic
    return PaymentResult(
      success: false,
      message: 'Play Store integration coming soon',
    );
  }

  /// Process payment (Legacy Stripe method - removed logic)
  Future<PaymentResult> processPayment({
    required String clientSecret,
    required dynamic billingDetails,
  }) async {
    return PaymentResult(
      success: false,
      message: 'Stripe payments are no longer supported',
    );
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? errorCode;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.paymentIntentId,
  });
}
