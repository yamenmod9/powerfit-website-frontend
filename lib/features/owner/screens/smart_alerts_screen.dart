import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../core/utils/helpers.dart';
import '../providers/owner_dashboard_provider.dart';
import '../../../core/localization/app_strings.dart';

class SmartAlertsScreen extends StatelessWidget {
  const SmartAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.smartAlerts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OwnerDashboardProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<OwnerDashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const DashboardSkeleton();
          }

          if (provider.error != null) {
            return ErrorDisplay(
              message: provider.error!,
              onRetry: () => provider.refresh(),
            );
          }

          final alerts = provider.alerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.noAlerts,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.allSystemsNormal,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          // Group alerts by type
          final criticalAlerts = alerts.where((a) => a['priority'] == 'critical' || a['severity'] == 'high' || a['risk_level'] == 'high').toList();
          final warningAlerts = alerts.where((a) => a['priority'] == 'warning' || a['severity'] == 'medium' || a['risk_level'] == 'medium').toList();
          final infoAlerts = alerts.where((a) => a['priority'] == 'info' || a['severity'] == 'low' || a['risk_level'] == 'low').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Card(
                color: Colors.blue.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        context,
                        icon: Icons.error,
                        count: criticalAlerts.length,
                        label: S.critical,
                        color: Colors.red,
                      ),
                      _buildSummaryItem(
                        context,
                        icon: Icons.warning,
                        count: warningAlerts.length,
                        label: S.warning,
                        color: Colors.orange,
                      ),
                      _buildSummaryItem(
                        context,
                        icon: Icons.info,
                        count: infoAlerts.length,
                        label: S.info,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Critical Alerts
              if (criticalAlerts.isNotEmpty) ...[
                _buildSectionHeader(context, S.criticalAlerts, Colors.red),
                const SizedBox(height: 12),
                ...criticalAlerts.map((alert) => _buildAlertCard(context, alert, Colors.red)),
                const SizedBox(height: 24),
              ],

              // Warning Alerts
              if (warningAlerts.isNotEmpty) ...[
                _buildSectionHeader(context, S.warnings, Colors.orange),
                const SizedBox(height: 12),
                ...warningAlerts.map((alert) => _buildAlertCard(context, alert, Colors.orange)),
                const SizedBox(height: 24),
              ],

              // Info Alerts
              if (infoAlerts.isNotEmpty) ...[
                _buildSectionHeader(context, S.information, Colors.blue),
                const SizedBox(height: 12),
                ...infoAlerts.map((alert) => _buildAlertCard(context, alert, Colors.blue)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert, Color color) {
    final type = alert['type'] ?? alert['alert_type'] ?? 'general';
    final title = alert['title'] ?? alert['message'] ?? S.alert;
    final message = alert['description'] ?? alert['message'] ?? S.noDescription;
    final branchName = alert['branch_name'] ?? alert['branch'] ?? S.allBranches;
    final timestamp = alert['created_at'] ?? alert['timestamp'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getAlertIcon(type), color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != title) ...[
              const SizedBox(height: 4),
              Text(message, style: TextStyle(color: Colors.grey[700])),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(branchName),
              ],
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(DateHelper.getRelativeTime(DateHelper.parseDate(timestamp) ?? DateTime.now())),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text(S.viewDetails),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'dismiss',
              child: Row(
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 8),
                  Text(S.dismiss),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _showAlertDetails(context, alert);
            } else if (value == 'dismiss') {
              _dismissAlert(context, alert);
            }
          },
        ),
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'subscription':
      case 'expiring':
        return Icons.card_membership;
      case 'attendance':
      case 'absence':
        return Icons.person_off;
      case 'revenue':
      case 'financial':
        return Icons.attach_money;
      case 'complaint':
        return Icons.report_problem;
      case 'capacity':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(S.alertDetails),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.alertType(alert['type'] ?? S.na)),
              const SizedBox(height: 8),
              Text(S.alertMessage(alert['message'] ?? S.na)),
              const SizedBox(height: 8),
              Text(S.alertBranch(alert['branch_name'] ?? S.na)),
              const SizedBox(height: 8),
              Text(S.alertTime(alert['created_at'] ?? S.na)),
              if (alert['details'] != null) ...[
                const SizedBox(height: 8),
                Text(S.alertDetailsFull(alert['details'])),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(S.close),
          ),
        ],
      ),
    );
  }

  void _dismissAlert(BuildContext context, Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(S.alertDismissed),
        duration: Duration(seconds: 2),
      ),
    );
    // In production, you would call an API to mark the alert as read/dismissed
  }
}
