import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared/models/gym_model.dart';

/// Provides gym branding (colors, name, logo) to the entire app.
/// Loaded after login based on the gym the user belongs to.
class GymBrandingProvider extends ChangeNotifier {
  static const _storagePrefix = 'gym_branding_';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _gymName = 'Gym Management';
  Color _primaryColor = const Color(0xFFDC2626);
  Color _secondaryColor = const Color(0xFFEF4444);
  String? _logoUrl;
  bool _isSetupComplete = true;
  int? _gymId;
  String _emailDomain = 'test.com';

  GymBrandingProvider() {
    // Restore persisted branding on startup
    loadFromStorage();
  }

  String get gymName => _gymName;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  String? get logoUrl => _logoUrl;
  bool get isSetupComplete => _isSetupComplete;
  int? get gymId => _gymId;
  String get emailDomain => _emailDomain;

  /// Parse a hex color string like '#DC2626' or 'DC2626' to a Color.
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Convert a Color to hex string.
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Load branding from a GymModel (after login or gym setup).
  void loadFromGym(GymModel gym) {
    _gymId = gym.id;
    _gymName = gym.name;
    _primaryColor = hexToColor(gym.primaryColor);
    _secondaryColor = hexToColor(gym.secondaryColor);
    _logoUrl = gym.logoUrl;
    _isSetupComplete = gym.isSetupComplete;
    _emailDomain = gym.emailDomain;
    _persistToStorage();
    notifyListeners();
  }

  /// Update branding during Gym Setup Wizard.
  void updateBranding({
    String? gymName,
    Color? primaryColor,
    Color? secondaryColor,
    String? logoUrl,
    bool? isSetupComplete,
  }) {
    if (gymName != null) {
      _gymName = gymName;
      // Recalculate email domain
      final sanitized = gymName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      _emailDomain = '$sanitized.com';
    }
    if (primaryColor != null) _primaryColor = primaryColor;
    if (secondaryColor != null) _secondaryColor = secondaryColor;
    if (logoUrl != null) _logoUrl = logoUrl;
    if (isSetupComplete != null) _isSetupComplete = isSetupComplete;
    _persistToStorage();
    notifyListeners();
  }

  /// Reset to defaults (on logout).
  void reset() {
    _gymName = 'Gym Management';
    _primaryColor = const Color(0xFFDC2626);
    _secondaryColor = const Color(0xFFEF4444);
    _logoUrl = null;
    _isSetupComplete = true;
    _gymId = null;
    _emailDomain = 'test.com';
    _clearStorage();
    notifyListeners();
  }

  Future<void> _persistToStorage() async {
    await _storage.write(key: '${_storagePrefix}name', value: _gymName);
    await _storage.write(key: '${_storagePrefix}primary', value: colorToHex(_primaryColor));
    await _storage.write(key: '${_storagePrefix}secondary', value: colorToHex(_secondaryColor));
    if (_logoUrl != null) {
      await _storage.write(key: '${_storagePrefix}logo', value: _logoUrl!);
    }
    await _storage.write(key: '${_storagePrefix}setup', value: _isSetupComplete.toString());
    if (_gymId != null) {
      await _storage.write(key: '${_storagePrefix}id', value: _gymId.toString());
    }
    await _storage.write(key: '${_storagePrefix}domain', value: _emailDomain);
  }

  Future<void> loadFromStorage() async {
    final name = await _storage.read(key: '${_storagePrefix}name');
    final primary = await _storage.read(key: '${_storagePrefix}primary');
    final secondary = await _storage.read(key: '${_storagePrefix}secondary');
    final logo = await _storage.read(key: '${_storagePrefix}logo');
    final setup = await _storage.read(key: '${_storagePrefix}setup');
    final id = await _storage.read(key: '${_storagePrefix}id');
    final domain = await _storage.read(key: '${_storagePrefix}domain');

    if (name != null) _gymName = name;
    if (primary != null) _primaryColor = hexToColor(primary);
    if (secondary != null) _secondaryColor = hexToColor(secondary);
    _logoUrl = logo;
    if (setup != null) _isSetupComplete = setup == 'true';
    if (id != null) _gymId = int.tryParse(id);
    if (domain != null) _emailDomain = domain;
    notifyListeners();
  }

  Future<void> _clearStorage() async {
    for (final key in ['name', 'primary', 'secondary', 'logo', 'setup', 'id', 'domain']) {
      await _storage.delete(key: '$_storagePrefix$key');
    }
  }
}
