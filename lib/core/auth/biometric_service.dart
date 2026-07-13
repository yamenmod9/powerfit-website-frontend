import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service handling biometric authentication (Fingerprint / Face ID).
///
/// Flow:
///  1. User logs in with username+password.
///  2. User enables biometric in Settings → credentials are saved encrypted.
///  3. On next login / session expiry the login screen shows a biometric icon.
///  4. Tapping it triggers the OS biometric prompt.
///  5. On success, stored credentials are retrieved and an automatic login
///     is performed.
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys for biometric credentials
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUsernameKey = 'biometric_username';
  static const String _biometricPasswordKey = 'biometric_password';

  // ───────────────────── Device capability checks ─────────────────────

  /// Whether the device has biometric hardware available.
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Whether the device can currently check biometrics
  /// (i.e., at least one biometric is enrolled).
  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types
  /// (e.g. [BiometricType.fingerprint], [BiometricType.face]).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Convenience: device has hardware AND at least one biometric enrolled.
  Future<bool> isBiometricAvailable() async {
    final supported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    return supported && canCheck;
  }

  // ────────────────────── Authentication prompt ───────────────────────

  /// Show the native biometric prompt.  Returns `true` when the user
  /// successfully authenticates, `false` otherwise.
  Future<bool> authenticate({
    String reason = 'Please authenticate to log in',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // ──────────── Credential storage (encrypted via SecureStorage) ──────────

  /// Whether the user has enabled biometric login.
  Future<bool> isBiometricEnabled() async {
    if (kIsWeb) return false;
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Enable biometric login and store the user's credentials.
  Future<void> enableBiometric({
    required String username,
    required String password,
  }) async {
    if (kIsWeb) return;
    await _storage.write(key: _biometricEnabledKey, value: 'true');
    await _storage.write(key: _biometricUsernameKey, value: username);
    await _storage.write(key: _biometricPasswordKey, value: password);
  }

  /// Disable biometric login and wipe stored credentials.
  Future<void> disableBiometric() async {
    if (kIsWeb) return;
    await _storage.write(key: _biometricEnabledKey, value: 'false');
    await _storage.delete(key: _biometricUsernameKey);
    await _storage.delete(key: _biometricPasswordKey);
  }

  /// Retrieve stored credentials.
  /// Returns `null` if either value is missing.
  Future<Map<String, String>?> getStoredCredentials() async {
    if (kIsWeb) return null;
    final username = await _storage.read(key: _biometricUsernameKey);
    final password = await _storage.read(key: _biometricPasswordKey);
    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  /// Whether biometric is both enabled and we have stored credentials.
  Future<bool> canBiometricLogin() async {
    if (kIsWeb) return false;
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;
    final available = await isBiometricAvailable();
    if (!available) return false;
    final creds = await getStoredCredentials();
    return creds != null;
  }
}
