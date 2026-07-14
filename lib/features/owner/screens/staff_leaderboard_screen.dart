import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../core/utils/helpers.dart';
import '../providers/owner_dashboard_provider.dart';
import '../../../core/localization/app_strings.dart';

class StaffLeaderboardScreen extends StatelessWidget {
  const StaffLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.staffLeaderboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
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

          final employees = provider.employeePerformance;

          if (employees.isEmpty) {
            return Center(
              child: Text(S.noPerformanceData),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Performers Card
              Card(
                color: Colors.amber.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text(
                            S.topPerformers,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (employees.isNotEmpty)
                        ...employees.take(3).toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final employee = entry.value;
                          return _buildTopPerformerTile(context, employee, index + 1);
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // All Staff Performance
              Text(
                S.allStaffMembers,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...employees.asMap().entries.map((entry) {
                final index = entry.key;
                final employee = entry.value;
                return _buildEmployeeCard(context, employee, index + 1);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopPerformerTile(BuildContext context, Map<String, dynamic> employee, int rank) {
    final name = employee['full_name'] ?? employee['staff_name'] ?? employee['name'] ?? employee['employee_name'] ?? employee['username'] ?? 'Unknown';
    final revenue = (employee['total_revenue'] ?? employee['revenue'] ?? 0).toDouble();
    final transactions = employee['transactions_count'] ?? employee['customers'] ?? employee['customer_count'] ?? 0;

    Color medalColor;
    IconData medalIcon;
    switch (rank) {
      case 1:
        medalColor = Colors.amber;
        medalIcon = Icons.looks_one;
        break;
      case 2:
        medalColor = Colors.grey[400]!;
        medalIcon = Icons.looks_two;
        break;
      case 3:
        medalColor = Colors.brown[300]!;
        medalIcon = Icons.looks_3;
        break;
      default:
        medalColor = Colors.grey;
        medalIcon = Icons.star;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: medalColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: medalColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(medalIcon, color: medalColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      NumberHelper.formatCurrency(revenue),
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(S.transactionsCount(transactions as int)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Map<String, dynamic> employee, int rank) {
    final name = employee['full_name'] ?? employee['staff_name'] ?? employee['name'] ?? employee['employee_name'] ?? employee['username'] ?? 'Unknown';
    final role = employee['role'] ?? employee['position'] ?? 'Staff';
    final branch = employee['branch_name'] ?? employee['branch'] ?? 'N/A';
    final revenue = (employee['total_revenue'] ?? employee['revenue'] ?? 0).toDouble();
    final transactions = employee['transactions_count'] ?? employee['customers'] ?? employee['customer_count'] ?? 0;
    final retentionRate = (employee['retention_rate'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.work, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(role),
            const SizedBox(width: 12),
            Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(child: Text(branch, overflow: TextOverflow.ellipsis)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        icon: Icons.attach_money,
                        label: S.revenue,
                        value: NumberHelper.formatCurrency(revenue),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        icon: Icons.people,
                        label: S.transactions,
                        value: transactions.toString(),
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        icon: Icons.trending_up,
                        label: S.retention,
                        value: '${retentionRate.toStringAsFixed(1)}%',
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(), // Placeholder for future metrics
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.filterOptions),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort),
              title: Text(S.sortByRevenue),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(S.sortByCustomers),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: Text(S.sortByRetention),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.close),
          ),
        ],
      ),
    );
  }
}
