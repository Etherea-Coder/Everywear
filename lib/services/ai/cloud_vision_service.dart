import 'package:connectivity_plus/connectivity_plus.dart';

/// Cloud Vision Service
/// Repurposed as a connectivity utility after migration to Gemini (via Supabase Edge Function).
/// HuggingFace integration removed — Gemini is now the cloud AI tier.
class CloudVisionService {
  /// Check if device has an active internet connection
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }
}
