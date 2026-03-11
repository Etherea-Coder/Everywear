import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';

  /// Initialize payment service (no-op since Stripe is removed)
  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('Payment service initialized (Stripe removed)');
    }
  }

  /// Create payment intent for subscription
  Future<PaymentIntentResponse> createPaymentIntent({
    required int amount,
    required String currency,
    required String planId,
  }) async {
    // Return a dummy response since Stripe is removed
    return PaymentIntentResponse(
      clientSecret: '',
      success: true,
      message: 'Payment service disabled',
    );
  }

  /// Confirm payment (no-op since Stripe is removed)
  Future<PaymentResult> confirmPayment({
    required String paymentIntentId,
  }) async {
    return PaymentResult(
      success: false,
      message: 'Payment service is not available',
    );
  }

  /// Check if payment service is available
  bool get isAvailable => false;
}

class PaymentIntentResponse {
  final String clientSecret;
  final bool success;
  final String message;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.success,
    required this.message,
  });
}

class PaymentResult {
  final bool success;
  final String message;
  final String? errorCode;

  PaymentResult({
    required this.success,
    required this.message,
    this.errorCode,
  });
}
