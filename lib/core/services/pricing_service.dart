import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/pricing_model.dart';

/// Fetches region-aware pricing from the public, unauthenticated
/// GET /api/pricing endpoint. Never throws — every failure path (network
/// error, timeout, malformed response) resolves to null so the landing
/// page can fall back gracefully instead of blocking on a marketing page.
class PricingService {
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Pass [countryOverride] (an ISO 3166-1 alpha-2 code) to force a
  /// specific region, matching the backend's `?country=` param — used
  /// both for a user's manual region choice and for testing.
  Future<PricingData?> fetchPricing({String? countryOverride}) async {
    try {
      final response = await _dio.get(
        '/api/pricing',
        queryParameters:
            countryOverride != null ? {'country': countryOverride} : null,
      );
      if (response.statusCode == 200 && response.data is Map) {
        return PricingData.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Persists the visitor's manual region/currency choice so it sticks
/// across visits and takes precedence over auto-detection next time.
/// `null` means "auto-detect" (the default, first-visit state).
class PricingPreferences {
  static const _key = 'pricing_region_override';

  static Future<String?> getOverride() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Pass null to clear the override and go back to auto-detection.
  static Future<void> setOverride(String? countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (countryCode == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, countryCode);
    }
  }
}
