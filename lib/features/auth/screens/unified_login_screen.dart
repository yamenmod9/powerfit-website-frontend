import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/models/gym_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../client/core/auth/client_auth_provider.dart';
import '../widgets/login_shell.dart';

/// One login page for everyone — staff, admins, and members — used only by
/// the unified web build (web_main.dart). Submits to the staff endpoint
/// first; if that account doesn't exist there, falls back to the member
/// endpoint with the same credentials, so nobody has to pick a role up
/// front. Native single-audience builds keep their own LoginScreen /
/// WelcomeScreen — same shared [LoginShell] chrome, but each only ever
/// talks to one of the two backends.
class UnifiedLoginScreen extends StatefulWidget {
  final GymBrandingProvider staffBranding;
  final GymBrandingProvider clientBranding;

  const UnifiedLoginScreen({
    super.key,
    required this.staffBranding,
    required this.clientBranding,
  });

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoBiometric());
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoBiometric() async {
    if (_biometricAttempted) return;
    _biometricAttempted = true;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.canBiometricLogin) {
      await _handleBiometricLogin();
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.biometricLogin();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] != true) {
      setState(
        () => _errorMessage = result['message'] ?? S.biometricLoginFailed,
      );
    } else {
      _loadStaffGymBranding(result);
      _applyStaffLanguagePreference(result);
    }
  }

  void _loadStaffGymBranding(Map<String, dynamic> loginResult) {
    final gymJson = loginResult['gym'] as Map<String, dynamic>?;
    if (gymJson == null) return;
    widget.staffBranding.loadFromGym(GymModel.fromJson(gymJson));
  }

  void _applyStaffLanguagePreference(Map<String, dynamic> loginResult) {
    context
        .read<LocaleProvider>()
        .applyAccountPreference(loginResult['preferred_language'] as String?);
  }

  void _loadClientGymBranding(Map<String, dynamic> loginData) {
    final gymJson = loginData['gym'] as Map<String, dynamic>?;
    if (gymJson == null) return;
    widget.clientBranding.loadFromGym(GymModel.fromJson(gymJson));
  }

  void _applyClientLanguagePreference(Map<String, dynamic> loginData) {
    final customer = loginData['customer'] as Map<String, dynamic>?;
    context
        .read<LocaleProvider>()
        .applyAccountPreference(customer?['preferred_language'] as String?);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final authProvider = context.read<AuthProvider>();
    final staffResult = await authProvider.login(identifier, password);
    if (!mounted) return;
    if (staffResult['success'] == true) {
      setState(() => _isLoading = false);
      _loadStaffGymBranding(staffResult);
      _applyStaffLanguagePreference(staffResult);
      return;
    }

    // Not a staff/admin account — try it as a member login before giving up.
    final clientAuthProvider = context.read<ClientAuthProvider>();
    try {
      final clientData = await clientAuthProvider.login(identifier, password);
      if (!mounted) return;
      _loadClientGymBranding(clientData);
      _applyClientLanguagePreference(clientData);
      setState(() => _isLoading = false);
      if (!clientAuthProvider.passwordChanged) {
        context.goNamed('change-password', extra: true);
      } else {
        context.goNamed('home');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = staffResult['message'] ?? S.loginFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginShell(
      title: AppConstants.appName,
      subtitle: S.unifiedLoginSubtitle,
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      onHomeTap: () => context.go('/'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            loginFieldLabel(S.loginIdentifier),
            const SizedBox(height: 8),
            TextFormField(
              controller: _identifierController,
              style: const TextStyle(color: Colors.white),
              decoration: loginFieldDecoration(
                S.enterLoginIdentifier,
                Icons.person_outline,
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
              onFieldSubmitted: (_) => _handleLogin(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? S.passwordRequired : null,
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
            _biometricButton(context),
          ],
        ),
      ),
    );
  }

  Widget _biometricButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.canBiometricLogin) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleBiometricLogin,
              icon: const Icon(Icons.fingerprint, size: 26),
              label: Text(
                S.loginWithBiometrics,
                style: const TextStyle(fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: kLoginRed.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
