import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_strings.dart';

/// App-wide language preference (Arabic/English).
///
/// Syncs with [S.setArabic] so every `S.xxx` getter reflects the active
/// language, and persists locally via SharedPreferences for the pre-login
/// experience (landing page, login screen). Once a user logs in, their
/// account's own `preferred_language` (from the backend) takes precedence —
/// call [applyAccountPreference] right after a successful login/profile
/// fetch.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_language';

  bool _isArabic = true;

  LocaleProvider() {
    _loadPersisted();
  }

  bool get isArabic => _isArabic;
  Locale get locale => Locale(_isArabic ? 'ar' : 'en');

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      if (stored == 'ar' || stored == 'en') {
        _setInternal(stored == 'ar');
      }
    } catch (_) {
      // SharedPreferences unavailable — keep the Arabic default.
    }
  }

  void _setInternal(bool isArabic) {
    if (_isArabic == isArabic) return;
    _isArabic = isArabic;
    S.setArabic(isArabic);
    notifyListeners();
  }

  /// Explicit user choice — from the language setup step, or an in-app
  /// settings screen. Persists locally so it survives a future visit even
  /// before the user logs in again.
  Future<void> setArabic(bool isArabic) async {
    _setInternal(isArabic);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, isArabic ? 'ar' : 'en');
    } catch (_) {
      // Non-fatal — the in-memory value is still correct for this session.
    }
  }

  /// Call right after a successful login/profile fetch. Applies the
  /// account's own preferred_language if it's set ('ar' or 'en'), which
  /// takes precedence over whatever was stored locally on this device
  /// (e.g. a shared front-desk computer). A null/unset value means the
  /// account hasn't completed the language onboarding step yet — leave
  /// the current value as-is and let that step handle it.
  void applyAccountPreference(String? preferredLanguage) {
    if (preferredLanguage == 'ar') {
      _setInternal(true);
    } else if (preferredLanguage == 'en') {
      _setInternal(false);
    }
  }
}
