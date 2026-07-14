import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/auth/client_auth_provider.dart';
import '../core/theme/client_theme.dart';
import '../../shared/widgets/notification_settings_section.dart';

/// Profile / settings tab, styled to the PowerFit Member App design: an
/// avatar header, grouped setting rows on dark cards, and a red outlined
/// log-out action. All original actions are preserved.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _requestAccountDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteAccount),
        content: Text(S.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.requestDeletion),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final auth = context.read<ClientAuthProvider>();
      await auth.requestAccountDeletion();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.deleteAccountRequested),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      await auth.logout();
      if (context.mounted) context.goNamed('welcome');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.logout),
        content: Text(S.signOutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.logout),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ClientAuthProvider>().logout();
    }
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF3B82F6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientAuthProvider>().currentClient;

    return Container(
      color: ClientTheme.darkGrey,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _profileHeader(context, client?.fullName, client?.id),

            const SizedBox(height: 20),

            _group([
              _row(context,
                  icon: Icons.person_outline,
                  title: S.profileInformation,
                  onTap: () => _soon(context, S.profileEditingSoon)),
              _divider(),
              _row(context,
                  icon: Icons.card_membership_outlined,
                  title: S.manageSubscription,
                  onTap: () => context.pushNamed('subscription')),
              _divider(),
              _row(context,
                  icon: Icons.phone_outlined,
                  title: S.contactInformationSetting,
                  onTap: () => _soon(context, S.contactEditingSoon)),
            ]),

            const SizedBox(height: 16),

            // Notifications toggle (functional) + preferences.
            _group([
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: NotificationSettingsSection(),
              ),
              _divider(),
              _row(context,
                  icon: Icons.language,
                  title: S.language,
                  trailingText: S.arabicDefault,
                  onTap: () => _soon(context, S.languageComingSoon)),
              _divider(),
              _row(context,
                  icon: Icons.dark_mode_outlined,
                  title: S.theme,
                  trailingText: S.darkMode,
                  onTap: () => _soon(context, S.themeSelectionSoon)),
            ]),

            const SizedBox(height: 16),

            _group([
              _row(context,
                  icon: Icons.help_outline,
                  title: S.helpSupport,
                  onTap: () => _soon(context, S.helpSupportComingSoon)),
              _divider(),
              _row(context,
                  icon: Icons.info_outline,
                  title: S.about,
                  onTap: () => showAboutDialog(
                        context: context,
                        applicationName: S.gymClient,
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.fitness_center,
                            size: 48, color: ClientTheme.primaryRed),
                        children: [Text(S.modernGymApp)],
                      )),
              _divider(),
              _row(context,
                  icon: Icons.privacy_tip_outlined,
                  title: S.privacyPolicy,
                  onTap: () => _soon(context, S.privacyPolicySoon)),
              _divider(),
              _row(context,
                  icon: Icons.delete_forever,
                  title: S.deleteAccount,
                  danger: true,
                  onTap: () => _requestAccountDeletion(context)),
            ]),

            const SizedBox(height: 22),

            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(S.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String? name, int? id) {
    final initial =
        (name != null && name.isNotEmpty) ? name.substring(0, 1).toUpperCase() : 'G';
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
              color: ClientTheme.primaryRed, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        Text(name ?? S.guest,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        if (id != null) ...[
          const SizedBox(height: 2),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('#$id',
                style: const TextStyle(
                    color: ClientTheme.subtleGrey, fontSize: 13)),
          ),
        ],
      ],
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ClientTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Colors.white10);

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    final color = danger ? const Color(0xFFEF4444) : ClientTheme.primaryRed;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: danger ? const Color(0xFFEF4444) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            if (trailingText != null)
              Text(trailingText,
                  style: const TextStyle(
                      color: ClientTheme.subtleGrey, fontSize: 13))
            else
              const Icon(Icons.chevron_left,
                  size: 20, color: Color(0xFF6A6A6A)),
          ],
        ),
      ),
    );
  }
}
