import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/dash_charts.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/date_range_picker.dart';
import '../../../core/utils/helpers.dart';
import '../../finance/screens/money_management_view.dart';
import '../../owner/providers/owner_dashboard_provider.dart';
import '../../owner/widgets/add_staff_dialog.dart';
import '../../owner/widgets/staff_actions.dart';
import '../../owner/screens/smart_alerts_screen.dart';
import '../../owner/screens/branch_detail_screen.dart';
import '../../issues/screens/issues_screen.dart';
import '../../branch_manager/screens/branch_manager_settings_screen.dart';
import '../../../core/localization/app_strings.dart';

/// Regional manager console. Reuses the owner's dashboard provider — the
/// backend scopes every endpoint to the manager's branch group, so this is
/// the owner experience restricted to "your branches" (no branch creation,
/// no gym-level settings).
class RegionalManagerDashboard extends StatefulWidget {
  const RegionalManagerDashboard({super.key});

  @override
  State<RegionalManagerDashboard> createState() =>
      _RegionalManagerDashboardState();
}

class _RegionalManagerDashboardState extends State<RegionalManagerDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerDashboardProvider>().loadDashboardData();
    });
  }

  static List<String> get _titles => [
        S.overview,
        S.branches,
        S.staff,
        S.finance,
        S.complaints,
        S.issues,
      ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<OwnerDashboardProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final gymName = branding.isSetupComplete && branding.gymId != null
        ? branding.gymName
        : S.regionalManagerTitle;

    final body = provider.isLoading
        ? const DashboardSkeleton()
        : provider.error != null
            ? ErrorDisplay(
                message: provider.error!,
                onRetry: () => provider.refresh(),
              )
            : _buildCurrentTab(context, provider, authProvider);

    return DashboardShell(
      accent: Theme.of(context).colorScheme.primary,
      appTitle: 'PowerFit',
      roleTag: S.regionalManagerRole,
      userName: authProvider.username ?? S.manager,
      userRole: S.regionalManagerRole,
      selectedIndex: _selectedIndex,
      onSelect: (i) => setState(() => _selectedIndex = i),
      pageTitle: _selectedIndex == 0 ? gymName : _titles[_selectedIndex],
      pageSub: _selectedIndex == 0 ? S.yourBranches : null,
      navItems: [
        DashNavItem(Icons.dashboard_outlined, S.overview),
        DashNavItem(Icons.store_outlined, S.branches),
        DashNavItem(Icons.people_outline, S.staff),
        DashNavItem(Icons.assessment_outlined, S.finance),
        DashNavItem(Icons.report_problem_outlined, S.complaints),
        DashNavItem(Icons.flag_outlined, S.issues),
      ],
      actions: [
        DashIconAction(
          icon: Icons.date_range,
          tooltip: S.selectDateRange,
          onTap: () => showDateRangePickerDialog(
            context: context,
            initialStartDate: provider.startDate,
            initialEndDate: provider.endDate,
            onDateRangeSelected: provider.setDateRange,
          ),
        ),
        DashIconAction(
            icon: Icons.refresh,
            tooltip: S.refresh,
            onTap: () => provider.refresh()),
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
      floatingActionButton: _selectedIndex == 2 &&
              provider.branchComparison.isNotEmpty
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

  Widget _buildCurrentTab(BuildContext context, OwnerDashboardProvider provider,
      AuthProvider authProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context, provider, authProvider);
      case 1:
        return _buildBranchesTab(context, provider);
      case 2:
        return _buildStaffTab(context, provider);
      case 3:
        return _buildFinanceTab(context, provider);
      case 4:
        return _buildComplaintsTab(context, provider);
      case 5:
        return const IssuesScreen(embedded: true);
      default:
        return const SizedBox();
    }
  }

  // ─── OVERVIEW ────────────────────────────────────────────────────────

  Widget _buildOverviewTab(BuildContext context,
      OwnerDashboardProvider provider, AuthProvider authProvider) {
    final accent = Theme.of(context).colorScheme.primary;
    final rd = provider.revenueData ?? {};
    final totalRevenue = (rd['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final activeSubscriptions = rd['active_subscriptions'] ?? 0;
    final totalCustomers = rd['total_customers'] ?? 0;
    final totalBranches =
        rd['total_branches'] ?? provider.branchComparison.length;
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final chart = _revenueByBranchCard(context, provider, accent);
    final alerts = _alertsCard(context, provider, accent);

    return DashBody(
      onRefresh: () => provider.refresh(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeCard(context, authProvider.username ?? S.manager),
          const SizedBox(height: 22),
          DashKpiGrid(cards: [
            DashKpiCard(
                label: S.totalRevenue,
                value: NumberHelper.formatCurrency(totalRevenue),
                icon: Icons.attach_money,
                iconColor: accent),
            DashKpiCard(
                label: S.totalCustomers,
                value: NumberHelper.formatNumber(totalCustomers),
                icon: Icons.people,
                iconColor: accent),
            DashKpiCard(
                label: S.activeSubs,
                value: NumberHelper.formatNumber(activeSubscriptions),
                icon: Icons.card_membership,
                iconColor: DashColors.emerald,
                valueColor: DashColors.emerald),
            DashKpiCard(
                label: S.branches,
                value: NumberHelper.formatNumber(totalBranches),
                icon: Icons.store,
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
          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 17, child: chart),
                  const SizedBox(width: 18),
                  Expanded(flex: 10, child: alerts),
                ],
              ),
            )
          else ...[
            chart,
            const SizedBox(height: 18),
            alerts,
          ],
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
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _revenueByBranchCard(
      BuildContext context, OwnerDashboardProvider provider, Color accent) {
    final branches = provider.branchComparison.take(7).toList();
    return DashSectionCard(
      title: S.revenue,
      accent: accent,
      child: branches.isEmpty
          ? _emptyHint(S.noRevenueData)
          : DashBarChart(
              accent: accent,
              bars: [
                for (final b in branches)
                  ((b['revenue'] ?? 0) as num).toDouble(),
              ],
              labels: [
                for (final b in branches) _shortName(_branchName(b)),
              ],
            ),
    );
  }

  Widget _alertsCard(
      BuildContext context, OwnerDashboardProvider provider, Color accent) {
    final alerts = provider.alerts.take(4).toList();
    return DashSectionCard(
      title: S.recentAlerts,
      accent: accent,
      actionLabel: alerts.isEmpty ? null : S.viewAll,
      onAction: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SmartAlertsScreen())),
      child: alerts.isEmpty
          ? _emptyHint(S.allClear)
          : Column(
              children: [
                for (var i = 0; i < alerts.length; i++) ...[
                  DashAlertTile(
                    color: _riskColor(alerts[i]['risk_level'], accent),
                    title: alerts[i]['title'] ?? alerts[i]['message'] ?? S.alert,
                    subtitle: alerts[i]['description'] ?? '',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SmartAlertsScreen())),
                  ),
                  if (i < alerts.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  String _branchName(Map b) =>
      (b['name'] ?? b['branch_name'] ?? S.unknown).toString();

  String _shortName(String s) {
    final first = s.split(' ').first;
    return first.length > 8 ? first.substring(0, 8) : first;
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(text,
              style: const TextStyle(color: DashColors.subtle, fontSize: 14)),
        ),
      );

  Color _riskColor(dynamic risk, Color accent) {
    switch (risk) {
      case 'high':
        return accent;
      case 'medium':
        return DashColors.amber;
      default:
        return DashColors.blue;
    }
  }

  // ─── BRANCHES ────────────────────────────────────────────────────────

  Widget _buildBranchesTab(
      BuildContext context, OwnerDashboardProvider provider) {
    if (provider.branchComparison.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_outlined,
                size: 80, color: Color(0xFF6B7590)),
            const SizedBox(height: 20),
            Text(S.noBranchesYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9AA3B8))),
          ],
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
          final customers = branch['customers'] ??
              branch['customers_count'] ??
              branch['customer_count'] ??
              0;
          final activeSubs =
              branch['active_subscriptions'] ?? branch['capacity'] ?? 0;
          final staffCount = branch['staff_count'] ?? 0;
          final city = branch['city'] ?? '';
          final address = branch['address'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.store,
                              color: Theme.of(context).primaryColor, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              if (city.isNotEmpty || address.isNotEmpty)
                                Text(
                                  address.isNotEmpty ? address : city,
                                  style: const TextStyle(
                                      color: Color(0xFF6B7590), fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBranchStat(Icons.people, '$customers', S.customers),
                        _buildBranchStat(
                            Icons.card_membership, '$activeSubs', S.activeSubs),
                        _buildBranchStat(Icons.badge, '$staffCount', S.staff),
                        if (revenue > 0)
                          _buildBranchStat(Icons.attach_money,
                              NumberHelper.formatCurrency(revenue), S.revenue),
                      ],
                    ),
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
        Icon(icon, size: 20, color: const Color(0xFF6B7590)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7590))),
      ],
    );
  }

  // ─── STAFF ───────────────────────────────────────────────────────────

  Widget _buildStaffTab(
      BuildContext context, OwnerDashboardProvider provider) {
    if (provider.employeePerformance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outlined,
                size: 64, color: Color(0xFF9AA3B8)),
            const SizedBox(height: 16),
            Text(S.noStaffFound,
                style: const TextStyle(
                    fontSize: 16, color: Color(0xFF9AA3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.employeePerformance.length,
        itemBuilder: (context, index) {
          final employee = provider.employeePerformance[index];
          final name = employee['full_name'] ??
              employee['staff_name'] ??
              employee['name'] ??
              employee['username'] ??
              S.unknown;
          final role =
              (employee['role'] ?? 'Employee').toString().replaceAll('_', ' ');
          final revenue =
              (employee['total_revenue'] ?? employee['revenue'] ?? 0)
                  .toDouble();
          final transactions = employee['transactions_count'] ??
              employee['transaction_count'] ??
              0;
          final branchName = employee['branch_name'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(role,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (branchName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  branchName,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7590)),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.transactionsCount(transactions as int),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7590)),
                      ),
                    ],
                  ),
                  StaffActions(
                    staff: Map<String, dynamic>.from(employee as Map),
                    apiService: provider.apiService,
                    viewerRole: context.read<AuthProvider>().userRole,
                    onChanged: () => provider.refresh(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── FINANCE ─────────────────────────────────────────────────────────

  Widget _buildFinanceTab(
      BuildContext context, OwnerDashboardProvider provider) {
    final revenueData = provider.revenueData ?? {};
    final totalRevenue =
        (revenueData['total_revenue'] as num?)?.toDouble() ?? 0.0;

    return MoneyManagementView(
      earnings: totalRevenue,
      expenses: provider.expenses,
      categoryTotals: provider.expensesByCategory,
      branches: [
        for (final branch in provider.branchComparison)
          Map<String, dynamic>.from(branch as Map),
      ],
      defaultBranchId: provider.selectedBranchId,
      canReview: true,
      onRefresh: () => provider.refresh(),
    );
  }

  // ─── COMPLAINTS ──────────────────────────────────────────────────────

  Widget _buildComplaintsTab(
      BuildContext context, OwnerDashboardProvider provider) {
    if (provider.complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(S.noComplaints,
                style: const TextStyle(
                    fontSize: 16, color: Color(0xFF9AA3B8))),
            const SizedBox(height: 8),
            Text(S.allClear,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9AA3B8))),
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
          final statusColor = isResolved
              ? Colors.green
              : isInProgress
                  ? Colors.blue
                  : Colors.orange;
          final statusIcon = isResolved
              ? Icons.check_circle
              : isInProgress
                  ? Icons.hourglass_top
                  : Icons.error_outline;
          final description = c['description'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
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
                      style: const TextStyle(
                          color: Color(0xFF243050), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFF9AA3B8)),
                      const SizedBox(width: 4),
                      Text(c['branch_name'] ?? S.unknownBranch,
                          style: const TextStyle(
                              color: Color(0xFF6B7590), fontSize: 12)),
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
    final creatorRole = context.read<AuthProvider>().userRole;
    showDialog(
      context: context,
      builder: (_) => AddStaffDialog(
        apiService: apiService,
        creatorRole: creatorRole,
        onStaffCreated: () {
          context.read<OwnerDashboardProvider>().refresh();
        },
      ),
    );
  }
}
