import 'package:flutter/material.dart';
import '../../core/services/fcm_notification_service.dart';
import '../../core/localization/app_strings.dart';

/// Reusable notification toggle section for all role-specific settings screens.
class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  late bool _enabled;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _enabled = FcmNotificationService().notificationsEnabled;
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    await FcmNotificationService().setNotificationsEnabled(value);
    if (mounted) {
      setState(() {
        _enabled = value;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? S.notificationsActivated : S.notificationsDeactivated,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          S.notifications,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            secondary: Icon(
              _enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: _enabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(S.enableNotifications),
            subtitle: Text(
              _enabled ? S.notificationsEnabled : S.notificationsDisabled,
              style: TextStyle(
                color: _enabled ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
            value: _enabled,
            onChanged: _loading ? null : _toggle,
          ),
        ),
      ],
    );
  }
}
