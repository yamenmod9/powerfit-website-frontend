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
      body: GridView.count(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Extra bottom padding for navbar
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3, // Increased for more vertical space
        children: [
          _buildOperationCard(
            context,
            title: S.activateSubscription,
            icon: Icons.card_membership,
            color: Colors.green,
            onTap: () => _showActivateSubscriptionDialog(context),
          ),
          _buildOperationCard(
            context,
            title: S.renewSubscription,
            icon: Icons.refresh,
            color: Colors.teal,
            onTap: () => _showRenewSubscriptionDialog(context),
          ),
          _buildOperationCard(
            context,
            title: S.freezeSubscription,
            icon: Icons.pause_circle,
            color: Colors.indigo,
            onTap: () => _showFreezeSubscriptionDialog(context),
          ),
          _buildOperationCard(
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

  Widget _buildOperationCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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

