import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import './supabase_service.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';

  /// Initialize Stripe with publishable key
  static Future<void> initialize() async {
    try {
      const String publishableKey = String.fromEnvironment(
        'STRIPE_PUBLISHABLE_KEY',
        defaultValue: '',
      );

      if (publishableKey.isEmpty) {
        if (kDebugMode) {
          print(
            'Stripe initialization skipped: STRIPE_PUBLISHABLE_KEY not configured',
          );
        }
        return;
      }

      Stripe.publishableKey = publishableKey;

      if (kIsWeb) {
        await Stripe.instance.applySettings();
      }

      if (kDebugMode) {
        print(
          'Stripe initialized successfully for ${kIsWeb ? 'web' : 'mobile'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Stripe initialization error: $e');
      }
    }
  }

  /// Create payment intent for subscription
  Future<PaymentIntentResponse> createPaymentIntent({
    required double amount,
    required String userId,
    required String planType,
    String currency = 'usd',
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Invalid amount: Amount must be greater than 0');
      }

      if (userId.isEmpty) {
        throw Exception('Invalid parameters: userId cannot be empty');
      }

      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please login and try again.');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session found. Please login again.');
      }

      final response = await _dio.post(
        '$_baseUrl/create-subscription-payment',
        data: {
          'amount': amount,
          'currency': currency,
          'user_id': userId,
          'plan_type': planType,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return PaymentIntentResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to create payment intent: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.response?.data != null) {
        if (e.response?.data['error'] != null) {
          errorMessage = 'Payment error: ${e.response?.data['error']}';
        } else {
          errorMessage =
              'Server error: ${e.response?.statusMessage ?? 'Unknown error'}';
        }
      } else if (e.message?.contains('SocketException') == true) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Process payment using CardField + confirmPayment
  Future<PaymentResult> processPayment({
    required String clientSecret,
    required BillingDetails billingDetails,
  }) async {
    try {
      if (clientSecret.isEmpty) {
        throw Exception('Invalid payment configuration');
      }

      if (Stripe.publishableKey.isEmpty) {
        throw Exception('Payment service not properly initialized');
      }

      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(billingDetails: billingDetails),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return PaymentResult(
          success: true,
          message: 'Payment completed successfully',
          paymentIntentId: paymentIntent.id,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment was not completed. Status: ${paymentIntent.status}',
        );
      }
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        message: _getStripeErrorMessage(e),
        errorCode: e.error.code.name,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  String _getStripeErrorMessage(StripeException e) {
    switch (e.error.code) {
      case FailureCode.Canceled:
        return 'Payment was cancelled';
      case FailureCode.Failed:
        return 'Payment failed. Please try again.';
      case FailureCode.Timeout:
        return 'Payment timed out. Please try again.';
      default:
        return e.error.localizedMessage ?? 'Payment failed. Please try again.';
    }
  }
}

class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['client_secret'],
      paymentIntentId: json['payment_intent_id'],
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
