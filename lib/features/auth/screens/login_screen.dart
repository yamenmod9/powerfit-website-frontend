import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/models/gym_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/login_shell.dart';

/// Staff/admin login for the native single-audience app (main.dart and
/// super_admin_main.dart). Backend resolves the role after submit. Keeps
/// validation, gym branding, and biometric login. Shares its visual chrome
/// with [WelcomeScreen] (native member app) and UnifiedLoginScreen (web
/// build) via [LoginShell] — this screen only owns the staff-specific form
/// and submit logic, since it's the only one of the three with a backend
/// that resolves staff/admin roles.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
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
    _usernameController.dispose();
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
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] != true) {
        setState(
          () => _errorMessage = result['message'] ?? S.biometricLoginFailed,
        );
      } else {
        _loadGymBranding(result);
        _applyLanguagePreference(result);
      }
    }
  }

  void _loadGymBranding(Map<String, dynamic> loginResult) {
    final gymJson = loginResult['gym'] as Map<String, dynamic>?;
    if (gymJson == null) return;
    context.read<GymBrandingProvider>().loadFromGym(GymModel.fromJson(gymJson));
  }

  /// Applies the account's saved language preference, if any — a brand new
  /// staff account has none yet, which the router sends to the onboarding
  /// language step instead of a dashboard.
  void _applyLanguagePreference(Map<String, dynamic> loginResult) {
    context
        .read<LocaleProvider>()
        .applyAccountPreference(loginResult['preferred_language'] as String?);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        _loadGymBranding(result);
        _applyLanguagePreference(result);
      } else {
        setState(() => _errorMessage = result['message'] ?? S.loginFailed);
      }
    }
  }

  String _title(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final showBranding = auth.isAuthenticated &&
        branding.isSetupComplete &&
        branding.gymId != null;
    return showBranding ? branding.gymName : AppConstants.appName;
  }

  @override
  Widget build(BuildContext context) {
    return LoginShell(
      title: _title(context),
      subtitle: S.staffConsoleSubtitle,
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            loginFieldLabel(S.username),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: loginFieldDecoration(
                S.enterUsername,
                Icons.person_outline,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? S.usernameRequired
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
