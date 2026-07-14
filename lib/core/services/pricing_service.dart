import 'package:dio/dio.dart';
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
