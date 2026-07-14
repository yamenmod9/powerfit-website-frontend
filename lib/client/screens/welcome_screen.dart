import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/auth/client_auth_provider.dart';
import '../core/theme/client_theme.dart';
import '../../core/providers/gym_branding_provider.dart';
import '../../shared/models/gym_model.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Member login, styled to the PowerFit Member App welcome design: a crimson
/// logo glowing on a dark radial ground above the sign-in form.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(S.pleaseEnterCredentials),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<ClientAuthProvider>();
      final data = await authProvider.login(identifier, password);
      if (!mounted) return;

      _loadGymBranding(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(S.loginSuccessful),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.darkGrey,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.7),
                  radius: 1.0,
                  colors: [Color(0xFF2A0A12), ClientTheme.darkGrey],
                  stops: [0.0, 0.6],
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Logo mark.
                      Center(child: _logoMark(88)),
                      const SizedBox(height: 26),

                      const Text(
                        S.gymMemberPortal,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        S.yourGymInPocket,
                        style: TextStyle(
                          color: ClientTheme.textGrey,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      TextField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: S.phoneOrEmail,
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: S.enterPhoneOrEmail,
                          helperText: S.credentialsFromReception,
                        ),
                        keyboardType: TextInputType.text,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: S.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: S.firstTimeHint,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SmallLoadingIndicator()
                            : const Text(S.login),
                      ),
                      const SizedBox(height: 28),

                      // New-member hint.
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ClientTheme.cardGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ClientTheme.primaryRed.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: ClientTheme.primaryRed,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              S.newMember,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              S.visitReception,
                              style: TextStyle(
                                color: ClientTheme.textGrey,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                icon: const Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: ClientTheme.textGrey,
                ),
                label: const Text(
                  S.backToHome,
                  style: TextStyle(color: ClientTheme.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoMark(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.28),
      boxShadow: [
        BoxShadow(
          color: ClientTheme.primaryRed.withValues(alpha: 0.5),
          blurRadius: size * 0.4,
          offset: Offset(0, size * 0.14),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset('assets/icon/powerfit.jpeg', fit: BoxFit.cover),
    ),
  );
}
