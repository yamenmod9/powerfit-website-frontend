import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/date_range_picker.dart';
import '../../../core/utils/helpers.dart';
import '../providers/owner_dashboard_provider.dart';
import '../widgets/add_staff_dialog.dart';
import 'smart_alerts_screen.dart';
import 'staff_leaderboard_screen.dart';
import 'branch_detail_screen.dart';
import 'create_branch_screen.dart';
import 'owner_settings_screen.dart';
import '../../../core/localization/app_strings.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerDashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<OwnerDashboardProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final gymName = branding.isSetupComplete && branding.gymId != null
        ? branding.gymName
        : S.ownerDashboard;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(gymName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () {
              showDateRangePickerDialog(
                context: context,
                initialStartDate: dashboardProvider.startDate,
                initialEndDate: dashboardProvider.endDate,
                onDateRangeSelected: (start, end) {
                  dashboardProvider.setDateRange(start, end);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dashboardProvider.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OwnerSettingsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black54),
                    SizedBox(width: 8),
                    Text(S.logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: dashboardProvider.isLoading
          ? const LoadingIndicator(message: S.loadingDashboard)
          : dashboardProvider.error != null
              ? ErrorDisplay(
                  message: dashboardProvider.error!,
                  onRetry: () => dashboardProvider.refresh(),
                )
              : _buildCurrentTab(context, dashboardProvider, authProvider),
      floatingActionButton: _buildFab(context, dashboardProvider),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                height: 65,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                indicatorColor: Theme.of(context).primaryColor.withOpacity(0.15),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: S.overview,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.store_outlined),
                    selectedIcon: Icon(Icons.store),
                    label: S.branches,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outlined),
                    selectedIcon: Icon(Icons.people),
                    label: S.staff,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assessment_outlined),
                    selectedIcon: Icon(Icons.assessment),
                    label: S.finance,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.report_problem_outlined),
                    selectedIcon: Icon(Icons.report_problem),
                    label: S.issues,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildFab(BuildContext context, OwnerDashboardProvider provider) {
    // Tab 1 = Branches → show "Create Branch" FAB
    if (_selectedIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateBranchScreen()),
          );
          if (created == true) {
            provider.refresh();
          }
        },
        icon: const Icon(Icons.add_business),
        label: const Text(S.createBranch),
      );
    }
    // Tab 2 = Staff → show "Add Staff" FAB only if branches exist
    if (_selectedIndex == 2 && provider.branchComparison.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text(S.addStaff),
        backgroundColor: Colors.green,
      );
    }
    return null;
  }

  Widget _buildCurrentTab(BuildContext context, OwnerDashboardProvider provider, AuthProvider authProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context, provider, authProvider);
      case 1:
        return _buildBranchesTab(context, provider);
      case 2:
        return _buildEmployeesTab(context, provider);
      case 3:
        return _buildFinanceTab(context, provider);
      case 4:
        return _buildComplaintsTab(context, provider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab(BuildContext context, OwnerDashboardProvider provider, AuthProvider authProvider) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, authProvider.username ?? S.owner),
            const SizedBox(height: 20),
            Text(
              S.keyMetrics,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(context, provider),
            const SizedBox(height: 24),
            // Recent Alerts
            if (provider.alerts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.recentAlerts,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SmartAlertsScreen()),
                      );
                    },
                    child: const Text(S.viewAll),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAlertsList(context, provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.welcomeBack,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, OwnerDashboardProvider provider) {
    final revenueData = provider.revenueData ?? {};
    final totalRevenue = (revenueData['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final activeSubscriptions = revenueData['active_subscriptions'] ?? 0;
    final totalCustomers = revenueData['total_customers'] ?? 0;
    final totalBranches = revenueData['total_branches'] ?? provider.branchComparison.length;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200 ? 4 : width >= 800 ? 3 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: S.totalRevenue,
          value: NumberHelper.formatCurrency(totalRevenue),
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        StatCard(
          title: S.activeSubs,
          value: NumberHelper.formatNumber(activeSubscriptions),
          icon: Icons.card_membership,
          color: Colors.blue,
        ),
        StatCard(
          title: S.totalCustomers,
          value: NumberHelper.formatNumber(totalCustomers),
          icon: Icons.people,
          color: Colors.orange,
        ),
        StatCard(
          title: S.branches,
          value: NumberHelper.formatNumber(totalBranches),
          icon: Icons.store,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAlertsList(BuildContext context, OwnerDashboardProvider provider) {
    return Column(
      children: provider.alerts.take(3).map((alert) => Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (alert['risk_level'] == 'high')
                ? Colors.red.withOpacity(0.1)
                : (alert['risk_level'] == 'medium')
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
            child: Icon(
              Icons.notifications_active,
              color: (alert['risk_level'] == 'high')
                  ? Colors.red
                  : (alert['risk_level'] == 'medium')
                      ? Colors.orange
                      : Colors.blue,
              size: 20,
            ),
          ),
          title: Text(alert['title'] ?? alert['message'] ?? S.alert),
          subtitle: Text(alert['description'] ?? ''),
          trailing: const Icon(Icons.chevron_right, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmartAlertsScreen()),
            );
          },
        ),
      )).toList(),
    );
  }

  // Other specific tab build methods...
  Widget _buildBranchesTab(BuildContext context, OwnerDashboardProvider provider) {
    if (provider.branchComparison.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 20),
              Text(
                S.noBranchesYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                S.createFirstBranchDesc,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateBranchScreen()),
                  );
                  if (created == true) provider.refresh();
                },
                icon: const Icon(Icons.add_business),
                label: const Text(S.createBranch),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.branchComparison.length,
        itemBuilder: (context, index) {
          final branch = provider.branchComparison[index];
          final id = branch['id'] ?? branch['branch_id'] ?? 0;
          final name = branch['name'] ?? branch['branch_name'] ?? S.unknown;
          final revenue = (branch['revenue'] ?? 0).toDouble();
          final customers = branch['customers'] ?? branch['customers_count'] ?? branch['customer_count'] ?? 0;
          final activeSubs = branch['active_subscriptions'] ?? branch['capacity'] ?? 0;
          final staffCount = branch['staff_count'] ?? 0;
          final score = branch['performance_score'];
          final city = branch['city'] ?? '';
          final isActive = branch['is_active'] ?? true;
          final address = branch['address'] ?? '';
          final phone = branch['phone'] ?? '';
          final manager = branch['manager'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BranchDetailScreen(
                      branchId: id,
                      branchName: name,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.store, color: Theme.of(context).primaryColor, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              if (city.isNotEmpty || address.isNotEmpty)
                                Text(
                                  address.isNotEmpty ? address : city,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (manager.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 13, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(manager, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: score >= 70 ? Colors.green.withOpacity(0.1) : score >= 40 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$score%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red,
                              ),
                            ),
                          ),
                        if (!isActive)
                          const Chip(label: Text(S.inactive), backgroundColor: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBranchStat(Icons.people, '$customers', S.customers),
                        _buildBranchStat(Icons.card_membership, '$activeSubs', S.activeSubs),
                        _buildBranchStat(Icons.badge, '$staffCount', S.staff),
                        if (revenue > 0) _buildBranchStat(Icons.attach_money, NumberHelper.formatCurrency(revenue), S.revenue),
                      ],
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmployeesTab(BuildContext context, OwnerDashboardProvider provider) {
    // If there are no branches yet, guide the owner to create one first
    if (provider.branchComparison.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outlined, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 20),
              Text(
                S.noStaffYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                S.createBranchFirst,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _selectedIndex = 1); // switch to branches tab
                },
                icon: const Icon(Icons.add_business),
                label: const Text(S.createBranch),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If branches exist but no staff yet
    if (provider.employeePerformance.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_outlined, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 20),
              Text(
                S.noStaffYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                S.addStaffDesc,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddStaffDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text(S.addStaff),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.employeePerformance.length + 2, // +2 for header buttons
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StaffLeaderboardScreen()),
                        );
                      },
                      icon: const Icon(Icons.emoji_events, size: 18),
                      label: const Text(S.leaderboard),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddStaffDialog(context),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text(S.addStaff),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (index == 1) {
            return const SizedBox(height: 4);
          }
          final employee = provider.employeePerformance[index - 2];
          final name = employee['full_name'] ?? employee['staff_name'] ?? employee['name'] ?? employee['employee_name'] ?? employee['username'] ?? S.unknown;
          final role = (employee['role'] ?? 'Employee').toString().replaceAll('_', ' ');
          final revenue = (employee['total_revenue'] ?? employee['revenue'] ?? 0).toDouble();
          final transactions = employee['transactions_count'] ?? 0;
          final branchName = employee['branch_name'] ?? '';

          Color roleColor;
          switch (role.toLowerCase()) {
            case 'branch manager':
              roleColor = Colors.purple;
              break;
            case 'front desk':
              roleColor = Colors.blue;
              break;
            case 'central accountant':
              roleColor = Colors.teal;
              break;
            default:
              roleColor = Colors.grey;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: roleColor.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(role, style: TextStyle(fontSize: 11, color: roleColor, fontWeight: FontWeight.w500)),
                            ),
                            if (branchName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  branchName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberHelper.formatCurrency(revenue),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.transactionsCount(transactions as int),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinanceTab(BuildContext context, OwnerDashboardProvider provider) {
    final revenueData = provider.revenueData ?? {};
    final totalRevenue = (revenueData['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (revenueData['total_expenses'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (revenueData['net_profit'] as num?)?.toDouble() ?? (totalRevenue - totalExpenses);
    final activeSubscriptions = revenueData['active_subscriptions'] ?? 0;
    final totalCustomers = revenueData['total_customers'] ?? 0;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          SimpleStatCard(
            label: S.totalRevenue,
            value: NumberHelper.formatCurrency(totalRevenue),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          SimpleStatCard(
            label: S.totalExpenses,
            value: NumberHelper.formatCurrency(totalExpenses),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          SimpleStatCard(
            label: S.netProfit,
            value: NumberHelper.formatCurrency(netProfit),
            color: netProfit >= 0 ? Colors.blue : Colors.red,
          ),
          const SizedBox(height: 12),
          SimpleStatCard(
            label: S.activeSubscriptions,
            value: NumberHelper.formatNumber(activeSubscriptions),
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          SimpleStatCard(
            label: S.totalCustomers,
            value: NumberHelper.formatNumber(totalCustomers),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsTab(BuildContext context, OwnerDashboardProvider provider) {
    if (provider.complaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(S.noComplaints, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text(S.allClear, style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.complaints.length,
        itemBuilder: (context, index) {
          final c = provider.complaints[index];
          final status = c['status'] ?? 'open';
          final isResolved = status == 'closed' || status == 'resolved';
          final isInProgress = status == 'in_progress';
          final statusColor = isResolved ? Colors.green : isInProgress ? Colors.blue : Colors.orange;
          final statusIcon = isResolved ? Icons.check_circle : isInProgress ? Icons.hourglass_top : Icons.error_outline;
          final description = c['description'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c['title'] ?? S.complaint,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(c['branch_name'] ?? S.unknownBranch, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (c['customer_name'] != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.person, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(c['customer_name'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final apiService = context.read<OwnerDashboardProvider>().apiService;
    showDialog(
      context: context,
      builder: (_) => AddStaffDialog(
        apiService: apiService,
        onStaffCreated: () {
          context.read<OwnerDashboardProvider>().refresh();
        },
      ),
    );
  }
}
