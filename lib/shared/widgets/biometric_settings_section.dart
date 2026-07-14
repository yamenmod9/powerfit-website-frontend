import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/localization/app_strings.dart';

/// Reusable biometric toggle section for all role-specific settings screens.
///
/// Shows a "Security" section with a toggle to enable/disable biometric login.
/// When enabling, it walks the user through a setup flow:
///   1. Shows available biometric types (fingerprint / face) on the device.
///   2. Triggers the native OS biometric prompt so the user verifies their
///      biometric before we store anything.
///   3. Asks for the current password so credentials can be saved securely.
class BiometricSettingsSection extends StatelessWidget {
  const BiometricSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // If the device doesn't support biometrics at all, hide the section.
    if (!authProvider.isBiometricAvailable) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          S.security,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint,
                  color: authProvider.isBiometricEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: const Text(S.biometricLogin),
                subtitle: Text(
                  authProvider.isBiometricEnabled
                      ? S.useBiometricToLogin
                      : S.quicklyLoginWithBiometric,
                ),
                value: authProvider.isBiometricEnabled,
                onChanged: (enabled) {
                  if (enabled) {
                    _startBiometricSetup(context, authProvider);
                  } else {
                    _confirmDisableBiometric(context, authProvider);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────── Setup flow (3 steps) ────────────────────

  /// Step 1 – Show available types and let the user proceed.
  Future<void> _startBiometricSetup(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final biometricService = authProvider.biometricService;
    final availableTypes = await biometricService.getAvailableBiometrics();

    final hasFingerprint = availableTypes.contains(BiometricType.fingerprint);
    final hasFace = availableTypes.contains(BiometricType.face);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.setupBiometricLogin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show the appropriate icon(s)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasFingerprint) ...[
                  _BiometricTypeCard(
                    icon: Icons.fingerprint,
                    label: S.fingerprint,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ],
                if (hasFingerprint && hasFace) const SizedBox(width: 16),
                if (hasFace) ...[
                  _BiometricTypeCard(
                    icon: Icons.face,
                    label: S.faceId,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ],
                // Fallback when the OS doesn't report a specific type
                if (!hasFingerprint && !hasFace) ...[
                  _BiometricTypeCard(
                    icon: Icons.verified_user,
                    label: S.biometric,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Text(
              hasFingerprint && hasFace
                  ? S.deviceSupportsBoth
                  : hasFingerprint
                      ? S.deviceSupportsFingerprint
                      : hasFace
                          ? S.deviceSupportsFaceId
                          : S.deviceSupportsBiometric,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyBiometric(context, authProvider);
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text(S.continueText),
          ),
        ],
      ),
    );
  }

  /// Step 2 – Trigger the native biometric prompt.
  Future<void> _verifyBiometric(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final biometricService = authProvider.biometricService;

    final authenticated = await biometricService.authenticate(
      reason: S.verifyBiometricToEnable,
    );

    if (!context.mounted) return;

    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(S.biometricVerificationFailed),
        ),
      );
      return;
    }

    // Biometric verified – now ask for the password.
    _askPasswordAndEnable(context, authProvider);
  }

  /// Step 3 – Ask for the current password, store everything.
  void _askPasswordAndEnable(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final passwordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: Icon(
            Icons.check_circle_outline,
            color: Theme.of(ctx).colorScheme.primary,
            size: 48,
          ),
          title: const Text(S.biometricVerified),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                S.enterPasswordToComplete,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: S.currentPassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(S.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) return;

                Navigator.pop(ctx);

                await authProvider.enableBiometric(
                  username: authProvider.username ?? '',
                  password: password,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(S.biometricEnabled),
                    ),
                  );
                }
              },
              child: const Text(S.enable),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Disable flow ─────────────────────

  void _confirmDisableBiometric(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.disableBiometricLogin),
        content: const Text(
          S.disableBiometricConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.disableBiometric();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(S.biometricDisabled),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(S.disable),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Helper widget ───────────────────────

/// Small card shown in the setup dialog to visualise the available
/// biometric type (fingerprint icon, face icon, etc.).
class _BiometricTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BiometricTypeCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
