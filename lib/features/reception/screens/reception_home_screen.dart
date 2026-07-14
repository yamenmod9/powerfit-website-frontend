import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../core/utils/helpers.dart';
import '../providers/reception_provider.dart';
import '../widgets/register_customer_dialog.dart';
import '../widgets/activate_subscription_dialog.dart';
import 'health_report_screen.dart';
import 'qr_scanner_screen.dart';
import '../../../core/localization/app_strings.dart';

class ReceptionHomeScreen extends StatefulWidget {
  const ReceptionHomeScreen({super.key});

  @override
  State<ReceptionHomeScreen> createState() => _ReceptionHomeScreenState();
}

class _ReceptionHomeScreenState extends State<ReceptionHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceptionProvider>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final gymName = branding.isSetupComplete && branding.gymId != null
        ? branding.gymName
        : S.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: Text(gymName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const DashboardSkeleton()
          : provider.error != null
              ? ErrorDisplay(
                  message: provider.error!,
                  onRetry: () => provider.refresh(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Extra bottom padding for navbar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Section
                      Text(
                        S.dashboardStats,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Statistics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.8, // Increased for more vertical space
                        children: [
                          _buildStatCard(
                            context,
                            title: S.totalCustomers,
                            value: '${provider.recentCustomers.length}',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            context,
                            title: S.activeSubscriptions,
                            value: '${provider.activeSubscriptionsCount}',
                            icon: Icons.card_membership,
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            context,
                            title: S.newToday,
                            value: '${_getNewTodayCount(provider)}',
                            icon: Icons.person_add,
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            context,
                            title: S.complaints,
                            value: '${provider.complaintsCount}',
                            icon: Icons.report_problem,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick Access Buttons
                      Text(
                        S.quickActions,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRegisterCustomerDialog(context),
                              icon: const Icon(Icons.person_add),
                              label: Text(S.registerCustomer),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showActivateSubscriptionDialog(context),
                              icon: const Icon(Icons.card_membership),
                              label: Text(S.activateSub),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // QR Scanner Button - Full Width
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRScannerScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 28),
                          label: Text(S.scanCustomerQR),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recent Customers
                      Row(
                        children: [
                          Text(
                            S.recentCustomers,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => provider.refresh(),
                            child: Text(S.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.recentCustomers.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text(S.noRecentCustomers)),
                          ),
                        )
                      else
                        ...provider.recentCustomers.take(5).map((customer) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HealthReportScreen(customer: customer),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                child: Text(customer.fullName[0].toUpperCase()),
                              ),
                              title: Text(customer.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (customer.phone != null)
                                    Text(customer.phone!),
                                  if (customer.bmi != null)
                                    Text('${S.bmi}: ${customer.bmi!.toStringAsFixed(1)} (${customer.bmiCategory})'),
                                ],
                              ),
                              trailing: customer.createdAt != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateHelper.getRelativeTime(customer.createdAt!),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    )
                                  : Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getNewTodayCount(ReceptionProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return provider.recentCustomers.where((customer) {
      if (customer.createdAt == null) return false;
      final createdDate = DateTime(
        customer.createdAt!.year,
        customer.createdAt!.month,
        customer.createdAt!.day,
      );
      return createdDate.isAtSameMomentAs(today);
    }).length;
  }

  void _showRegisterCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RegisterCustomerDialog(),
    );
  }

  void _showActivateSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ActivateSubscriptionDialog(),
    );
  }
}
