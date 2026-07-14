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

/// Staff/admin login, styled to the PowerFit Login design: a dark centered
/// card glowing crimson, with the member-entry link. Backend resolves the
/// role after submit. Keeps validation, gym branding, and biometric login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bg = Color(0xFF121212);
  static const _cardBg = Color(0xFF1E1E1E);
  static const _fieldBg = Color(0xFF2A2A2A);
  static const _red = Color(0xFFDC2626);
  static const _muted = Color(0xFFB0B0B0);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.1),
                  radius: 1.2,
                  colors: [Color(0xFF1E1E1E), _bg],
                  stops: [0.0, 0.65],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _card(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logoMark(32),
                    const SizedBox(width: 10),
                    const Text(
                      'PowerFit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back, size: 16, color: _muted),
                label: Text(
                  S.backToHome,
                  style: TextStyle(color: _muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandingLogo(context),
          const SizedBox(height: 22),
          _title(context),
          const SizedBox(height: 8),
          Text(
            S.staffConsoleSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            _errorBox(context),
            const SizedBox(height: 18),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label(S.username),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
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
                _label(S.password),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    S.enterPassword,
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _muted,
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
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF991B1B),
                      elevation: 8,
                      shadowColor: _red.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SmallLoadingIndicator()
                        : Text(
                            S.login,
                            style: TextStyle(
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
          const SizedBox(height: 24),
          _divider(),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.go('/client/welcome'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              S.memberEntry,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            S.roleAutoResolved,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF808080), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Text(
            'Version ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF5A5A5A), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _brandingLogo(BuildContext context) {
    final branding = context.watch<GymBrandingProvider>();
    final hasLogo = branding.logoUrl != null && branding.logoUrl!.isNotEmpty;
    if (hasLogo) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            branding.logoUrl!,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => _logoMark(72),
          ),
        ),
      );
    }
    return Center(child: _logoMark(72));
  }

  Widget _title(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final displayName =
        auth.isAuthenticated &&
            branding.isSetupComplete &&
            branding.gymId != null
        ? branding.gymName
        : AppConstants.appName;
    return Text(
      displayName,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w900,
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
                style: TextStyle(fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: _red.withValues(alpha: 0.6)),
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

  Widget _errorBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.14),
        border: Border.all(color: _red.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 14),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, size: 18, color: Color(0xFFF87171)),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white10)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            S.or,
            style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _label(String text) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _fieldDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6A6A6A)),
      prefixIcon: Icon(icon, color: _muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border(Colors.white.withValues(alpha: 0.12)),
      focusedBorder: border(_red, 1.5),
      errorBorder: border(const Color(0xFFEF4444)),
      focusedErrorBorder: border(const Color(0xFFEF4444), 1.5),
    );
  }

  Widget _logoMark(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.28),
      boxShadow: [
        BoxShadow(
          color: _red.withValues(alpha: 0.5),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset('assets/icon/powerfit.jpeg', fit: BoxFit.cover),
    ),
  );
}
