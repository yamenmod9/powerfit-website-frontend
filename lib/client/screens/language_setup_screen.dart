import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers/locale_provider.dart';
import '../core/auth/client_auth_provider.dart';
import '../core/theme/client_theme.dart';

/// Shown once, right after a member's first login, when the account has no
/// `preferred_language` set yet — mirrors the gym owner setup wizard's
/// language step but as a standalone screen (members have no setup wizard).
class LanguageSetupScreen extends StatefulWidget {
  const LanguageSetupScreen({super.key});

  @override
  State<LanguageSetupScreen> createState() => _LanguageSetupScreenState();
}

class _LanguageSetupScreenState extends State<LanguageSetupScreen> {
  String _selectedLanguage = 'ar';
  bool _isSaving = false;

  Future<void> _confirm() async {
    setState(() => _isSaving = true);
    try {
      await context.read<ClientAuthProvider>().setPreferredLanguage(_selectedLanguage);
      if (mounted) {
        context.read<LocaleProvider>().setArabic(_selectedLanguage == 'ar');
      }
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.languageSaveFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLanguageOption({
    required String code,
    required String label,
  }) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? ClientTheme.primaryRed.withValues(alpha: 0.15)
              : ClientTheme.cardGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? ClientTheme.primaryRed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.translate,
              color: isSelected ? ClientTheme.primaryRed : ClientTheme.textGrey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? ClientTheme.primaryRed : Colors.white,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: ClientTheme.primaryRed),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ClientTheme.darkGrey,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ClientTheme.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 64,
                    color: ClientTheme.primaryRed,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    S.chooseYourLanguage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    S.languageUsedThroughout,
                    style: const TextStyle(color: ClientTheme.textGrey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                _buildLanguageOption(code: 'ar', label: S.arabicLanguageName),
                const SizedBox(height: 16),
                _buildLanguageOption(code: 'en', label: S.englishLanguageName),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(S.continueText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
