import 'package:flutter/material.dart';
import '../widgets/activate_subscription_dialog.dart';
import '../widgets/renew_subscription_dialog.dart';
import '../widgets/freeze_subscription_dialog.dart';
import '../widgets/stop_subscription_dialog.dart';
import '../../../core/localization/app_strings.dart';

class SubscriptionOperationsScreen extends StatelessWidget {
  const SubscriptionOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.subscriptionOperations),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Extra bottom padding for navbar
        children: [
          _buildOperationRow(
            context,
            title: S.activateSubscription,
            icon: Icons.card_membership,
            color: Colors.green,
            onTap: () => _showActivateSubscriptionDialog(context),
          ),
          _buildOperationRow(
            context,
            title: S.renewSubscription,
            icon: Icons.refresh,
            color: Colors.teal,
            onTap: () => _showRenewSubscriptionDialog(context),
          ),
          _buildOperationRow(
            context,
            title: S.freezeSubscription,
            icon: Icons.pause_circle,
            color: Colors.indigo,
            onTap: () => _showFreezeSubscriptionDialog(context),
          ),
          _buildOperationRow(
            context,
            title: S.stopSubscription,
            icon: Icons.stop_circle,
            color: Colors.red,
            onTap: () => _showStopSubscriptionDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA3B8)),
      ),
    );
  }

  void _showActivateSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ActivateSubscriptionDialog(),
    );
  }

  void _showRenewSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RenewSubscriptionDialog(),
    );
  }

  void _showFreezeSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FreezeSubscriptionDialog(),
    );
  }

  void _showStopSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StopSubscriptionDialog(),
    );
  }
}

