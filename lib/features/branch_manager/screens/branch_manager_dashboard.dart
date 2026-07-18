import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/dash_charts.dart';
import '../../../core/utils/helpers.dart';
import '../../finance/screens/money_management_view.dart';
import '../../owner/widgets/add_staff_dialog.dart';
import '../../owner/widgets/staff_actions.dart';
import '../../reception/screens/customers_list_screen.dart';
import '../../issues/screens/issues_screen.dart';
import '../providers/branch_manager_provider.dart';
import 'branch_manager_settings_screen.dart';

class BranchManagerDashboard extends StatefulWidget {
  const BranchManagerDashboard({super.key});

  @override
  State<BranchManagerDashboard> createState() => _BranchManagerDashboardState();
}

class _BranchManagerDashboardState extends State<BranchManagerDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchManagerProvider>().loadDashboardData();
    });
  }

  static List<String> get _titles =>
      [S.overview, S.members, S.staff, S.moneyManagement, S.complaints, S.issues];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<BranchManagerProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final gymName = branding.isSetupComplete && branding.gymId != null
        ? branding.gymName
        : S.branchManagerTitle;

    final body = provider.isLoading
        ? const DashboardSkeleton()
        : provider.error != null
            ? ErrorDisplay(
                message: provider.error!,
                onRetry: () => provider.loadDashboardData(),
              )
            : _buildCurrentTab(context, provider, authProvider);

    return DashboardShell(
      accent: Theme.of(context).colorScheme.primary,
      appTitle: 'PowerFit',
      roleTag: S.branchManagerRole,
      userName: authProvider.username ?? S.manager,
      userRole: S.branchManagerRole,
      selectedIndex: _selectedIndex,
      onSelect: (i) => setState(() => _selectedIndex = i),
      pageTitle: _selectedIndex == 0 ? gymName : _titles[_selectedIndex],
      pageSub: _selectedIndex == 0 ? S.performanceOverview : null,
      navItems: [
        DashNavItem(Icons.dashboard_outlined, S.overview),
        DashNavItem(Icons.people_outline, S.members),
        DashNavItem(Icons.badge_outlined, S.staff),
        DashNavItem(Icons.account_balance_wallet_outlined, S.moneyManagement),
        DashNavItem(Icons.report_problem_outlined, S.complaints),
        DashNavItem(Icons.flag_outlined, S.issues),
      ],
      actions: [
        DashIconAction(
            icon: Icons.refresh,
            tooltip: S.refresh,
            onTap: () => provider.loadDashboardData()),
        DashIconAction(
          icon: Icons.settings_outlined,
          tooltip: S.settings,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BranchManagerSettingsScreen())),
        ),
      ],
      onLogout: authProvider.logout,
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showAddStaffDialog(context),
              icon: const Icon(Icons.person_add),
              label: Text(S.addStaff),
              backgroundColor: Colors.green,
            )
          : null,
      body: body,
    );
  }

  Widget _buildCurrentTab(BuildContext context, BranchManagerProvider provider, AuthProvider authProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context, provider, authProvider);
      case 1:
        // Members: the same customer console the front desk uses, scoped
        // server-side to this manager's branch.
        return const CustomersListScreen();
      case 2:
        return _buildStaffTab(provider);
      case 3:
        return _buildMoneyTab(context, provider, authProvider);
      case 4:
        return _buildComplaintsTab(provider);
      case 5:
        return const IssuesScreen(embedded: true);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMoneyTab(BuildContext context, BranchManagerProvider provider,
      AuthProvider authProvider) {
    final performance = provider.branchPerformance ?? {};
    final earnings = (performance['total_revenue'] ?? 0).toDouble();
    final branchId = int.tryParse(authProvider.branchId ?? '');

    return MoneyManagementView(
      earnings: earnings,
      expenses: provider.expenses,
      categoryTotals: provider.expensesByCategory,
      branches: branchId != null
          ? [
              {'id': branchId, 'name': S.branchManagerRole}
            ]
          : const [],
      defaultBranchId: branchId,
      canReview: true,
      onRefresh: () => provider.refresh(),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final provider = context.read<BranchManagerProvider>();
    final creatorRole = context.read<AuthProvider>().userRole;
    showDialog(
      context: context,
      builder: (_) => AddStaffDialog(
        apiService: provider.apiService,
        creatorRole: creatorRole,
        onStaffCreated: () => provider.refresh(),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, BranchManagerProvider provider,
      AuthProvider authProvider) {
    final accent = Theme.of(context).colorScheme.primary;
    final performance = provider.branchPerformance ?? {};
    final dailyOps = provider.dailyOperations ?? {};
    final todayRevenue =
        (dailyOps['total_revenue'] ?? performance['today_revenue'] ?? 0)
            .toDouble();
    final activeMembers = performance['active_members'] ??
        performance['active_subscriptions'] ??
        0;
    final totalCustomers = performance['total_customers'] ?? 0;
    final pendingComplaints = provider.complaints
        .where((c) =>
            c['status']?.toString().toLowerCase() == 'pending' ||
            c['status']?.toString().toLowerCase() == 'open')
        .length;
    final expiringCount = performance['expiring_subscriptions'] ?? 0;

    return DashBody(
      onRefresh: () => provider.loadDashboardData(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeCard(context, authProvider.username ?? S.manager),
          const SizedBox(height: 22),
          DashKpiGrid(cards: [
            DashKpiCard(
                label: S.todaysRevenue,
                value: NumberHelper.formatCurrency(todayRevenue),
                icon: Icons.attach_money,
                iconColor: accent),
            DashKpiCard(
                label: S.activeMembers,
                value: NumberHelper.formatNumber(activeMembers),
                icon: Icons.people,
                iconColor: DashColors.emerald,
                valueColor: DashColors.emerald),
            DashKpiCard(
                label: S.totalCustomers,
                value: NumberHelper.formatNumber(totalCustomers),
                icon: Icons.person,
                iconColor: DashColors.blue),
            DashKpiCard(
                label: expiringCount > 0 ? S.expiringSoon(expiringCount) : S.pendingIssues,
                value: NumberHelper.formatNumber(
                    expiringCount > 0 ? expiringCount : pendingComplaints),
                icon: expiringCount > 0 ? Icons.timer_off : Icons.report_problem,
                iconColor: DashColors.amber),
          ]),
          const SizedBox(height: 20),
          DashRevenueTrendCard(
            points: provider.revenueTrend,
            period: provider.trendPeriod,
            onPeriodChanged: provider.setTrendPeriod,
            accent: accent,
          ),
          const SizedBox(height: 20),
          DashExpenseCategoryCard(
            categories: provider.expensesByCategory,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard(BuildContext context, String name) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.welcomeBack,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 15)),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStaffTab(BranchManagerProvider provider) {
    final staffList = provider.staff;
    if (staffList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outlined, size: 64, color: Color(0xFF9AA3B8)),
            SizedBox(height: 16),
            Text(S.noStaffFound, style: TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadDashboardData(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: staffList.length,
        itemBuilder: (context, index) {
          final member = staffList[index];
          final name = member['full_name'] ?? member['username'] ?? S.unknown;
          final role = (member['role'] ?? 'employee').toString().replaceAll('_', ' ');
          final email = member['email'] ?? '';
          final phone = member['phone'] ?? '';
          final isActive = member['is_active'] ?? true;

          Color roleColor;
          switch (role.toLowerCase()) {
            case 'branch manager':
              roleColor = Colors.purple;
              break;
            case 'front desk':
              roleColor = Colors.blue;
              break;
            case 'central accountant':
            case 'branch accountant':
              roleColor = Colors.teal;
              break;
            default:
              roleColor = Color(0xFF9AA3B8);
          }

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(S.inactive, style: TextStyle(fontSize: 11, color: Colors.red)),
                              ),
                            ],
                          ],
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email, size: 13, color: Color(0xFF9AA3B8)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(email, style: TextStyle(fontSize: 12, color: Color(0xFF6B7590)), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 13, color: Color(0xFF9AA3B8)),
                              const SizedBox(width: 4),
                              Text(phone, style: TextStyle(fontSize: 12, color: Color(0xFF6B7590))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  StaffActions(
                    staff: Map<String, dynamic>.from(member as Map),
                    apiService: provider.apiService,
                    viewerRole: context.read<AuthProvider>().userRole,
                    onChanged: () => provider.loadDashboardData(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplaintsTab(BranchManagerProvider provider) {
    // Show all complaints
    final complaints = provider.complaints;

    if (complaints.isEmpty) {
      return Center(child: Text(S.noComplaints));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final c = complaints[index];
        final isPending = c['status'] == 'pending' || c['status'] == 'open' || c['status'] == 'in_progress';
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPending ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              child: Icon(
                isPending ? Icons.warning : Icons.check_circle,
                color: isPending ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(c['title'] ?? c['subject'] ?? S.complaint),
            subtitle: Text(
              c['description'] ?? S.noDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Chip(
              label: Text(c['status'] ?? S.unknown),
              backgroundColor: isPending ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              labelStyle: TextStyle(color: isPending ? Colors.red : Colors.green),
            ),
          ),
        );
      },
    );
  }
}
