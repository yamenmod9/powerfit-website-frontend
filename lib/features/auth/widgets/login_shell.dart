import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';

/// Shared palette for every login screen in the app (native staff/admin,
/// native member, and the unified web login) — kept in one place so the
/// three screens stay visually identical without copy-pasting hex values.
const kLoginBg = Color(0xFF121212);
const kLoginCardBg = Color(0xFF1E1E1E);
const kLoginFieldBg = Color(0xFF2A2A2A);
const kLoginRed = Color(0xFFDC2626);
const kLoginMuted = Color(0xFFB0B0B0);

/// Shared dark PowerFit-styled chrome for every login screen: header,
/// gradient background, card, logo, title/subtitle, and error box. Each
/// call site supplies its own form fields via [child] — the fields differ
/// (username vs. phone/email) and each screen submits to a different
/// backend, so only the surrounding shell is shared.
class LoginShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? errorMessage;
  final VoidCallback? onDismissError;

  /// Null hides the header's home link — the native staff and member apps
  /// have no landing page to return to; only the web build does.
  final VoidCallback? onHomeTap;
  final Widget child;

  const LoginShell({
    super.key,
    required this.title,
    required this.subtitle,
    this.errorMessage,
    this.onDismissError,
    this.onHomeTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLoginBg,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.1),
                  radius: 1.2,
                  colors: [Color(0xFF1E1E1E), kLoginBg],
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
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        loginLogoMark(32),
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
    );
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
              onHomeTap != null ? InkWell(onTap: onHomeTap, child: logo) : logo,
              const Spacer(),
              if (onHomeTap != null)
                TextButton.icon(
                  onPressed: onHomeTap,
                  icon: const Icon(Icons.arrow_back, size: 16, color: kLoginMuted),
                  label: Text(S.backToHome, style: const TextStyle(color: kLoginMuted)),
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
        color: kLoginCardBg,
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
          Center(child: loginLogoMark(72)),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kLoginMuted, fontSize: 15),
          ),
          const SizedBox(height: 28),
          if (errorMessage != null) ...[
            _errorBox(context),
            const SizedBox(height: 18),
          ],
          child,
          const SizedBox(height: 20),
          Text(
            'Version ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF5A5A5A), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kLoginRed.withValues(alpha: 0.14),
        border: Border.all(color: kLoginRed.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 14),
            ),
          ),
          if (onDismissError != null)
            InkWell(
              onTap: onDismissError,
              child: const Icon(Icons.close, size: 18, color: Color(0xFFF87171)),
            ),
        ],
      ),
    );
  }
}

Widget loginLogoMark(double size) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(size * 0.28),
    boxShadow: [
      BoxShadow(
        color: kLoginRed.withValues(alpha: 0.5),
        blurRadius: size >= 60 ? 18 : 14,
        offset: Offset(0, size >= 60 ? 6 : 4),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.28),
    child: Image.asset('assets/icon/powerfit.jpeg', fit: BoxFit.cover),
  ),
);

Widget loginFieldLabel(String text) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: Text(
    text,
    style: const TextStyle(
      color: kLoginMuted,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
);

InputDecoration loginFieldDecoration(
  String hint,
  IconData icon, {
  Widget? suffix,
  String? helperText,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF6A6A6A)),
    helperText: helperText,
    helperMaxLines: 2,
    prefixIcon: Icon(icon, color: kLoginMuted, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: kLoginFieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: border(Colors.white.withValues(alpha: 0.12)),
    focusedBorder: border(kLoginRed, 1.5),
    errorBorder: border(const Color(0xFFEF4444)),
    focusedErrorBorder: border(const Color(0xFFEF4444), 1.5),
  );
}
