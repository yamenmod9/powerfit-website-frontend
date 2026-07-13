class AppConfig {
  static const String appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _developmentApiBaseUrl = String.fromEnvironment('DEV_API_BASE_URL');
  static const String _stagingApiBaseUrl = String.fromEnvironment('STAGING_API_BASE_URL');
  static const String _productionApiBaseUrl = String.fromEnvironment('PROD_API_BASE_URL');

  static bool get isDevelopment => appEnvironment == 'development';
  static bool get isStaging => appEnvironment == 'staging';
  static bool get isProduction => appEnvironment == 'production';

  static String get apiBaseUrl {
    final direct = _apiBaseUrl.trim();
    if (direct.isNotEmpty) return direct;

    if (isDevelopment) {
      final value = _developmentApiBaseUrl.trim();
      if (value.isNotEmpty) return value;
    }

    if (isStaging) {
      final value = _stagingApiBaseUrl.trim();
      if (value.isNotEmpty) return value;
    }

    if (isProduction) {
      final value = _productionApiBaseUrl.trim();
      if (value.isNotEmpty) return value;
    }

    throw StateError(
      'Missing API base URL. Provide API_BASE_URL or an environment-specific define.',
    );
  }
}