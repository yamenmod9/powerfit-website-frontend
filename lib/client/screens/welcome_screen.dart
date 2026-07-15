import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/auth/client_auth_provider.dart';
import '../../core/providers/gym_branding_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../shared/models/gym_model.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../features/auth/widgets/login_shell.dart';

/// Member login for the native single-audience client app (client_main.dart).
/// Shares its visual chrome with [LoginScreen] (native staff/admin app) and
/// UnifiedLoginScreen (web build) via [LoginShell] — this screen only owns
/// the member-specific form and submit logic, since it's the only one of
/// the three with a backend that authenticates members.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadGymBranding(Map<String, dynamic> loginData) {
    final gymJson = loginData['gym'] as Map<String, dynamic>?;
    if (gymJson == null) return;
    final branding = context.read<GymBrandingProvider>();
    branding.loadFromGym(GymModel.fromJson(gymJson));
  }

  /// Applies the member's saved language preference, if any — a brand new
  /// account has none yet, which the router sends to the language setup
  /// step instead of the home screen.
  void _applyLanguagePreference(Map<String, dynamic> loginData) {
    final customer = loginData['customer'] as Map<String, dynamic>?;
    context
        .read<LocaleProvider>()
        .applyAccountPreference(customer?['preferred_language'] as String?);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<ClientAuthProvider>();
      final data = await authProvider.login(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      _loadGymBranding(data);
      _applyLanguagePreference(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.loginSuccessful),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (!authProvider.passwordChanged) {
        context.goNamed('change-password', extra: true);
      } else {
        context.goNamed('home');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginShell(
      title: S.gymMemberPortal,
      subtitle: S.yourGymInPocket,
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            loginFieldLabel(S.phoneOrEmail),
            const SizedBox(height: 8),
            TextFormField(
              controller: _identifierController,
              style: const TextStyle(color: Colors.white),
              decoration: loginFieldDecoration(
                S.enterPhoneOrEmail,
                Icons.person_outline,
                helperText: S.credentialsFromReception,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? S.loginIdentifierRequired
                  : null,
            ),
            const SizedBox(height: 18),
            loginFieldLabel(S.password),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: loginFieldDecoration(
                S.enterPassword,
                Icons.lock_outline,
                helperText: S.firstTimeHint,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: kLoginMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _login(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? S.passwordRequired : null,
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLoginRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF991B1B),
                  elevation: 8,
                  shadowColor: kLoginRed.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SmallLoadingIndicator()
                    : Text(
                        S.login,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kLoginFieldBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kLoginRed.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: kLoginRed,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.newMember,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.visitReception,
                    style: const TextStyle(color: kLoginMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
