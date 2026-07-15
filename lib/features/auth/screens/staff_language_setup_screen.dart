import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Shown once, right after a staff member's (front desk, accountant, branch
/// manager) first login, when the account has no `preferred_language` set
/// yet. Owners get a language step inside [GymSetupWizard] instead — this
/// screen is the standalone equivalent for everyone else.
class StaffLanguageSetupScreen extends StatefulWidget {
  const StaffLanguageSetupScreen({super.key});

  @override
  State<StaffLanguageSetupScreen> createState() => _StaffLanguageSetupScreenState();
}

class _StaffLanguageSetupScreenState extends State<StaffLanguageSetupScreen> {
  String _selectedLanguage = 'ar';
  bool _isSaving = false;

  String _defaultRouteFor(String? role) {
    switch (role) {
      case AppConstants.roleOwner:
        return '/owner';
      case AppConstants.roleBranchManager:
        return '/branch-manager';
      case AppConstants.roleFrontDesk:
      case 'reception':
        return '/reception';
      case AppConstants.roleCentralAccountant:
      case AppConstants.roleBranchAccountant:
      case 'accountant':
        return '/accountant';
      default:
        return '/login';
    }
  }

  Future<void> _confirm() async {
    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.setPreferredLanguage(_selectedLanguage);
      if (mounted) {
        context.read<LocaleProvider>().setArabic(_selectedLanguage == 'ar');
      }
      if (mounted) {
        context.go(_defaultRouteFor(authProvider.userRole));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.languageSaveFailed), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLanguageOption({required String code, required String label}) {
    final isSelected = _selectedLanguage == code;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.12) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : AppTheme.edge,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.translate, color: isSelected ? primary : AppTheme.mutedText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primary : Colors.white,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: primary),
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.language,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  S.chooseYourLanguage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  S.languageUsedThroughout,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildLanguageOption(code: 'ar', label: S.arabicLanguageName),
                const SizedBox(height: 16),
                _buildLanguageOption(code: 'en', label: S.englishLanguageName),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _confirm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving ? const SmallLoadingIndicator() : Text(S.continueText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
