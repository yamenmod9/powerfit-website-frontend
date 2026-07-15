import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/date_range_picker.dart';
import '../../../core/utils/helpers.dart';
import '../providers/accountant_provider.dart';
import 'accountant_settings_screen.dart';
import 'transaction_ledger_screen.dart';

class AccountantDashboard extends StatefulWidget {
  const AccountantDashboard({super.key});

  @override
  State<AccountantDashboard> createState() => _AccountantDashboardState();
}

class _AccountantDashboardState extends State<AccountantDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final provider = context.read<AccountantProvider>();
      final branchId = int.tryParse(authProvider.branchId ?? '');
      provider.initWithBranch(branchId);
      provider.loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<AccountantProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final gymName = branding.isSetupComplete && branding.gymId != null
        ? branding.gymName
        : S.accountantDashboard;

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
      roleTag: S.accountant,
      userName: authProvider.username ?? S.accountant,
      userRole: S.accountantRole,
      selectedIndex: _selectedIndex,
      onSelect: (i) => setState(() => _selectedIndex = i),
      pageTitle: _selectedIndex == 0 ? gymName : _titles[_selectedIndex],
      pageSub: _selectedIndex == 0 ? S.todaysSummary : null,
      navItems: [
        DashNavItem(Icons.dashboard_outlined, S.overview),
        DashNavItem(Icons.point_of_sale_outlined, S.sales),
        DashNavItem(Icons.money_off_outlined, S.expenses),
        DashNavItem(Icons.store_outlined, S.branches),
        DashNavItem(Icons.assessment_outlined, S.reports),
      ],
      actions: [
        DashIconAction(
          icon: Icons.date_range,
          tooltip: S.selectDateRange,
          onTap: () => showDateRangePickerDialog(
            context: context,
            initialStartDate: provider.startDate,
            initialEndDate: provider.endDate,
            onDateRangeSelected: (start, end) =>
                provider.setFilters(start: start, end: end),
          ),
        ),
        DashIconAction(
            icon: Icons.refresh, tooltip: S.refresh, onTap: () => provider.refresh()),
        DashIconAction(
          icon: Icons.settings_outlined,
          tooltip: S.settings,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccountantSettingsScreen())),
        ),
        DashIconAction(
            icon: Icons.logout, tooltip: S.logout, onTap: authProvider.logout),
      ],
      body: body,
    );
  }

  static List<String> get _titles => [
    S.overview,
    S.sales,
    S.expenses,
    S.branches,
    S.reports,
  ];

  Widget _buildCurrentTab(BuildContext context, AccountantProvider provider, AuthProvider authProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context, provider, authProvider);
      case 1:
        return _buildSalesTab(context, provider);
      case 2:
        return _buildExpensesTab(context, provider);
      case 3:
        return _buildBranchesTab(context, provider);
      case 4:
        return _buildReportsTab(context, provider);
      default:
        return const SizedBox();
    }
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────────────────

  Widget _buildOverviewTab(BuildContext context, AccountantProvider provider, AuthProvider authProvider) {
    final ds = provider.dailySales;
    final todaySales = (ds['total_sales'] ?? 0).toDouble();
    final monthlyRevenue = (ds['monthly_revenue'] ?? 0).toDouble();
    final monthlyExpenses = (ds['monthly_expenses'] ?? 0).toDouble();
    final monthlyNet = (ds['monthly_net'] ?? 0).toDouble();
    final pendingExpenses = ds['pending_expenses'] ?? 0;
    final transactionCount = ds['transaction_count'] ?? 0;
    final changePercent = (ds['change_percentage'] ?? 0).toDouble();
    final changeAmount = (ds['change_amount'] ?? 0).toDouble();

    final accent = Theme.of(context).colorScheme.primary;
    return DashBody(
      onRefresh: () => provider.loadDashboardData(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context, authProvider.username ?? S.accountant),
          const SizedBox(height: 22),
          DashKpiGrid(cards: [
            DashKpiCard(
                label: S.todaysSales,
                value: NumberHelper.formatCurrency(todaySales),
                icon: Icons.today,
                iconColor: accent),
            DashKpiCard(
                label: S.transactions,
                value: NumberHelper.formatNumber(transactionCount),
                icon: Icons.receipt_long,
                iconColor: DashColors.blue),
            DashKpiCard(
                label: S.revenue,
                value: NumberHelper.formatCurrency(monthlyRevenue),
                icon: Icons.trending_up,
                iconColor: DashColors.emerald,
                valueColor: DashColors.emerald),
            DashKpiCard(
                label: S.expenses,
                value: NumberHelper.formatCurrency(monthlyExpenses),
                icon: Icons.trending_down,
                iconColor: DashColors.amber),
            DashKpiCard(
                label: S.netProfit,
                value: NumberHelper.formatCurrency(monthlyNet),
                icon: Icons.account_balance_wallet,
                iconColor: monthlyNet >= 0 ? DashColors.blue : Colors.redAccent,
                valueColor: monthlyNet >= 0 ? null : Colors.redAccent),
            DashKpiCard(
                label: S.pending,
                value: NumberHelper.formatNumber(pendingExpenses),
                icon: Icons.pending_actions,
                iconColor: DashColors.amber),
          ]),
          const SizedBox(height: 20),
          _buildPaymentBreakdownCard(context, ds),
          if (changePercent != 0 || changeAmount != 0) ...[
            const SizedBox(height: 20),
            _buildComparisonCard(context, changeAmount, changePercent),
          ],
          if (provider.alerts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(S.alerts,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...provider.alerts.map((alert) => _buildAlertCard(context, alert)),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name) {
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

  Widget _buildPaymentBreakdownCard(BuildContext context, Map<String, dynamic> ds) {
    final cash = (ds['cash_sales'] ?? 0).toDouble();
    final network = (ds['network_sales'] ?? 0).toDouble();
    final transfer = (ds['transfer_sales'] ?? 0).toDouble();
    final total = cash + network + transfer;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.paymentBreakdown,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF243050))),
            const SizedBox(height: 12),
            _buildPaymentRow(S.cash, cash, total, Colors.green),
            const SizedBox(height: 8),
            _buildPaymentRow(S.networkCard, network, total, Colors.blue),
            const SizedBox(height: 8),
            _buildPaymentRow(S.transfer, transfer, total, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, double total, Color color) {
    final percent = total > 0 ? (amount / total * 100) : 0.0;
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(NumberHelper.formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text('${percent.toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7590))),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, double changeAmount, double changePercent) {
    final isPositive = changeAmount >= 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isPositive ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.monthOverMonth,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7590))),
                  const SizedBox(height: 4),
                  Text(
                    '${isPositive ? '+' : ''}${NumberHelper.formatCurrency(changeAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert) {
    final riskLevel = alert['risk_level'] ?? 'low';
    final alertColor = riskLevel == 'high' ? Colors.red
        : riskLevel == 'medium' ? Colors.orange : Colors.blue;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alertColor.withOpacity(0.1),
          child: Icon(Icons.notifications_active, color: alertColor, size: 20),
        ),
        title: Text(alert['title'] ?? S.alert,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(alert['description'] ?? '', style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // ─── SALES TAB ────────────────────────────────────────────────────────

  Widget _buildSalesTab(BuildContext context, AccountantProvider provider) {
    final transactions = provider.transactions;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: Column(
        children: [
          // Header with summary + link
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.salesAndTransactions,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(S.transactionsToday(transactions.length),
                        style: TextStyle(color: Color(0xFF6B7590), fontSize: 13)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final branchId = int.tryParse(context.read<AuthProvider>().branchId ?? '');
                    Navigator.push(context,
                      MaterialPageRoute(builder: (context) => TransactionLedgerScreen(branchId: branchId)));
                  },
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text(S.fullLedger),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Today summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(child: _buildMiniStat(S.total, NumberHelper.formatCurrency((provider.dailySales['total_sales'] ?? 0).toDouble()), Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildMiniStat(S.cash, NumberHelper.formatCurrency((provider.dailySales['cash_sales'] ?? 0).toDouble()), Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildMiniStat(S.card, NumberHelper.formatCurrency((provider.dailySales['network_sales'] ?? 0).toDouble()), Colors.blue)),
              ],
            ),
          ),

          const Divider(),

          // Transaction list
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Color(0xFF9AA3B8)),
                        const SizedBox(height: 16),
                        Text(S.noTransactionsToday, style: TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            final branchId = int.tryParse(context.read<AuthProvider>().branchId ?? '');
                            Navigator.push(context,
                              MaterialPageRoute(builder: (context) => TransactionLedgerScreen(branchId: branchId)));
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: Text(S.viewTransactionHistory),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final amount = (tx['amount'] ?? tx['total'] ?? 0).toDouble();
                      final paymentMethod = (tx['payment_method'] ?? 'cash').toString();
                      final customerName = tx['customer_name'] ?? tx['client_name'] ?? 'Walk-in';
                      final serviceName = tx['service_name'] ?? tx['subscription_name'] ?? '';
                      final date = tx['created_at'] ?? tx['date'] ?? '';

                      Color methodColor;
                      IconData methodIcon;
                      switch (paymentMethod.toLowerCase()) {
                        case 'network':
                        case 'card':
                          methodColor = Colors.blue;
                          methodIcon = Icons.credit_card;
                          break;
                        case 'transfer':
                        case 'online':
                          methodColor = Colors.purple;
                          methodIcon = Icons.send;
                          break;
                        default:
                          methodColor = Colors.green;
                          methodIcon = Icons.payments;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: methodColor.withOpacity(0.1),
                                child: Icon(methodIcon, color: methodColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (serviceName.isNotEmpty)
                                      Text(serviceName,
                                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7590))),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: methodColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(paymentMethod,
                                            style: TextStyle(fontSize: 10, color: methodColor, fontWeight: FontWeight.w500)),
                                        ),
                                        if (date.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(_formatTime(date),
                                            style: TextStyle(fontSize: 11, color: Color(0xFF9AA3B8))),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(NumberHelper.formatCurrency(amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF6B7590))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  // ─── EXPENSES TAB ─────────────────────────────────────────────────────

  Widget _buildExpensesTab(BuildContext context, AccountantProvider provider) {
    final expenses = provider.expenses;
    final ds = provider.dailySales;
    final totalExpenses = provider.approvedExpenseTotal > 0
        ? provider.approvedExpenseTotal + provider.pendingExpenseTotal
        : (ds['monthly_expenses'] ?? 0).toDouble();
    final pendingCount = expenses.where((e) => (e['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final approvedCount = expenses.where((e) => (e['status'] ?? '').toString().toLowerCase() == 'approved').length;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(child: _buildMiniStat(S.totalExpenses,
                  NumberHelper.formatCurrency(totalExpenses), Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _buildMiniStat(S.pending,
                  '$pendingCount', Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildMiniStat(S.approved,
                  '$approvedCount', Colors.green)),
              ],
            ),
          ),
          const Divider(),

          // Expense list
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 64, color: Color(0xFF9AA3B8)),
                        const SizedBox(height: 16),
                        Text(S.noExpensesFound, style: TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final amount = (expense['amount'] ?? 0).toDouble();
                      final status = (expense['status'] ?? 'pending').toString();
                      final category = expense['category'] ?? 'General';
                      final title = expense['title'] ?? expense['description'] ?? 'Expense';
                      final branchName = expense['branch_name'] ?? '';
                      final date = expense['date'] ?? expense['created_at'] ?? '';

                      Color statusColor;
                      IconData statusIcon;
                      switch (status.toLowerCase()) {
                        case 'approved':
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle;
                          break;
                        case 'rejected':
                          statusColor = Colors.red;
                          statusIcon = Icons.cancel;
                          break;
                        default:
                          statusColor = Colors.orange;
                          statusIcon = Icons.hourglass_top;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    child: const Icon(Icons.money_off, color: Colors.red, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF9AA3B8).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(category,
                                                style: TextStyle(fontSize: 10, color: Color(0xFF243050))),
                                            ),
                                            if (branchName.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Icon(Icons.store, size: 12, color: Color(0xFF9AA3B8)),
                                              const SizedBox(width: 2),
                                              Flexible(
                                                child: Text(branchName,
                                                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7590)),
                                                  overflow: TextOverflow.ellipsis),
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
                                      Text(NumberHelper.formatCurrency(amount),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, size: 12, color: statusColor),
                                            const SizedBox(width: 4),
                                            Text(status,
                                              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (date.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(date, style: TextStyle(fontSize: 11, color: Color(0xFF9AA3B8))),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── BRANCHES TAB ─────────────────────────────────────────────────────

  Widget _buildBranchesTab(BuildContext context, AccountantProvider provider) {
    final branches = provider.branchComparison;

    if (branches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Color(0xFF9AA3B8)),
            const SizedBox(height: 16),
            Text(S.noBranchData, style: TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: branches.length,
        itemBuilder: (context, index) {
          final branch = branches[index];
          final name = branch['name'] ?? branch['branch_name'] ?? S.unknown;
          final revenue = (branch['revenue'] ?? branch['total_revenue'] ?? 0).toDouble();
          final customers = branch['customers'] ?? branch['customers_count'] ?? branch['customer_count'] ?? 0;
          final activeSubs = branch['active_subscriptions'] ?? branch['capacity'] ?? 0;
          final staffCount = branch['staff_count'] ?? 0;
          final score = branch['performance_score'];
          final city = branch['city'] ?? '';
          final address = branch['address'] ?? '';
          final isActive = branch['is_active'] ?? true;
          final expenses = (branch['expenses'] ?? branch['total_expenses'] ?? 0).toDouble();
          final netProfit = revenue - expenses;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
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
                            Text(name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            if (city.isNotEmpty || address.isNotEmpty)
                              Text(address.isNotEmpty ? address : city,
                                style: TextStyle(color: Color(0xFF6B7590), fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (score != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$score%',
                            style: TextStyle(fontWeight: FontWeight.bold,
                              color: score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red)),
                        ),
                      if (!isActive)
                        Chip(label: Text(S.inactive), backgroundColor: Color(0xFF9AA3B8)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Financial stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBranchStat(Icons.attach_money, NumberHelper.formatCurrency(revenue), S.revenue),
                      _buildBranchStat(Icons.money_off, NumberHelper.formatCurrency(expenses), S.expenses),
                      _buildBranchStat(Icons.account_balance,
                        NumberHelper.formatCurrency(netProfit), S.netProfit,
                        color: netProfit >= 0 ? Colors.green : Colors.red),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBranchStat(Icons.people, '$customers', S.customers),
                      _buildBranchStat(Icons.card_membership, '$activeSubs', S.subscriptions),
                      _buildBranchStat(Icons.badge, '$staffCount', S.staff),
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

  Widget _buildBranchStat(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Color(0xFF6B7590)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF6B7590))),
      ],
    );
  }

  // ─── REPORTS TAB ──────────────────────────────────────────────────────

  Widget _buildReportsTab(BuildContext context, AccountantProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.financialReports,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Revenue Report
            if (provider.revenueReport != null) ...[
              _buildReportSection(context, S.revenueBreakdown, Icons.pie_chart, [
                _buildRevenueReport(context, provider.revenueReport!),
              ]),
              const SizedBox(height: 16),
            ],

            // Weekly Report
            if (provider.weeklyReport != null) ...[
              _buildReportSection(context, S.weeklyReport, Icons.calendar_view_week, [
                _buildWeeklyReport(context, provider.weeklyReport!),
              ]),
              const SizedBox(height: 16),
            ],

            // Monthly Report
            if (provider.monthlyReport != null) ...[
              _buildReportSection(context, S.monthlyReport, Icons.calendar_month, [
                _buildMonthlyReport(context, provider.monthlyReport!),
              ]),
              const SizedBox(height: 16),
            ],

            // Cash Differences
            if (provider.cashDifferences != null) ...[
              _buildReportSection(context, S.cashDifferences, Icons.compare_arrows, [
                _buildCashDifferencesReport(context, provider.cashDifferences!),
              ]),
              const SizedBox(height: 16),
            ],

            if (provider.revenueReport == null &&
                provider.weeklyReport == null &&
                provider.monthlyReport == null &&
                provider.cashDifferences == null)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Icon(Icons.assessment_outlined, size: 64, color: Color(0xFF9AA3B8)),
                    const SizedBox(height: 16),
                    Text(S.noReportData, style: TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
                    const SizedBox(height: 8),
                    Text(S.tryAdjustingDateRange, style: TextStyle(fontSize: 13, color: Color(0xFF9AA3B8))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueReport(BuildContext context, Map<String, dynamic> report) {
    final totalRevenue = (report['total_revenue'] ?? report['total'] ?? 0).toDouble();
    final byBranch = report['by_branch'] ?? report['branches'] ?? [];
    final byService = report['by_service'] ?? report['services'] ?? [];
    final byPayment = report['by_payment_method'] ?? report['payment_methods'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SimpleStatCard(
          label: S.totalRevenue,
          value: NumberHelper.formatCurrency(totalRevenue),
          color: Colors.green,
        ),
        const SizedBox(height: 12),

        if (byBranch is List && byBranch.isNotEmpty) ...[
          Text(S.byBranch, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF243050))),
          const SizedBox(height: 8),
          ...byBranch.map((b) => _buildReportDataRow(
            b['branch_name'] ?? b['name'] ?? S.unknown,
            (b['revenue'] ?? b['total'] ?? 0).toDouble(),
            totalRevenue,
            Colors.blue,
          )),
          const SizedBox(height: 12),
        ],

        if (byService is List && byService.isNotEmpty) ...[
          Text(S.byService, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF243050))),
          const SizedBox(height: 8),
          ...byService.map((s) => _buildReportDataRow(
            s['service_name'] ?? s['name'] ?? S.unknown,
            (s['revenue'] ?? s['total'] ?? 0).toDouble(),
            totalRevenue,
            Colors.purple,
          )),
          const SizedBox(height: 12),
        ],

        if (byPayment is List && byPayment.isNotEmpty) ...[
          Text(S.byPaymentMethod, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF243050))),
          const SizedBox(height: 8),
          ...byPayment.map((p) => _buildReportDataRow(
            p['payment_method'] ?? p['method'] ?? S.unknown,
            (p['revenue'] ?? p['total'] ?? 0).toDouble(),
            totalRevenue,
            Colors.teal,
          )),
        ],
      ],
    );
  }

  Widget _buildReportDataRow(String label, double value, double total, Color color) {
    final percent = total > 0 ? (value / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
              Text(NumberHelper.formatCurrency(value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text('${percent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7590))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              backgroundColor: Color(0xFF1B2748),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReport(BuildContext context, Map<String, dynamic> report) {
    final totalRevenue = (report['total_revenue'] ?? report['total'] ?? 0).toDouble();
    final totalExpenses = (report['total_expenses'] ?? report['expenses'] ?? 0).toDouble();
    final dailyBreakdown = report['daily_breakdown'] ?? report['days'] ?? report['daily'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SimpleStatCard(label: S.weeklyRevenue, value: NumberHelper.formatCurrency(totalRevenue), color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: SimpleStatCard(label: S.weeklyExpenses, value: NumberHelper.formatCurrency(totalExpenses), color: Colors.red)),
          ],
        ),
        if (dailyBreakdown is List && dailyBreakdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(S.dailyBreakdown, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF243050))),
          const SizedBox(height: 8),
          ...dailyBreakdown.map((day) {
            final dayName = day['day'] ?? day['date'] ?? '—';
            final dayRevenue = (day['revenue'] ?? day['total'] ?? 0).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dayName.toString(), style: const TextStyle(fontSize: 13)),
                  Text(NumberHelper.formatCurrency(dayRevenue),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMonthlyReport(BuildContext context, Map<String, dynamic> report) {
    final totalRevenue = (report['total_revenue'] ?? report['revenue'] ?? report['total'] ?? 0).toDouble();
    final totalExpenses = (report['total_expenses'] ?? report['expenses'] ?? 0).toDouble();
    final netProfit = (report['net_profit'] ?? report['net'] ?? (totalRevenue - totalExpenses)).toDouble();
    final totalTransactions = report['total_transactions'] ?? report['transactions'] ?? 0;
    final avgDaily = (report['avg_daily_revenue'] ?? report['average_daily'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SimpleStatCard(label: S.monthlyRevenue, value: NumberHelper.formatCurrency(totalRevenue), color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: SimpleStatCard(label: S.monthlyExpenses, value: NumberHelper.formatCurrency(totalExpenses), color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: SimpleStatCard(label: S.netProfit, value: NumberHelper.formatCurrency(netProfit), color: netProfit >= 0 ? Colors.blue : Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: SimpleStatCard(label: S.transactions, value: '$totalTransactions', color: Colors.purple)),
          ],
        ),
        if (avgDaily > 0) ...[
          const SizedBox(height: 8),
          SimpleStatCard(label: S.dailyAverageRevenue, value: NumberHelper.formatCurrency(avgDaily), color: Colors.teal),
        ],
      ],
    );
  }

  Widget _buildCashDifferencesReport(BuildContext context, Map<String, dynamic> report) {
    final items = report['items'] ?? report['differences'] ?? [];
    final totalDiff = (report['total_difference'] ?? report['total'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SimpleStatCard(
          label: S.totalCashDifference,
          value: NumberHelper.formatCurrency(totalDiff),
          color: totalDiff.abs() < 1 ? Colors.green : Colors.red,
        ),
        if (items is List && items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...items.take(10).map((item) {
            final diff = (item['difference'] ?? item['amount'] ?? 0).toDouble();
            final date = item['date'] ?? item['created_at'] ?? '';
            final branch = item['branch_name'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    diff.abs() < 1 ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: diff.abs() < 1 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (branch.isNotEmpty) Text(branch, style: const TextStyle(fontSize: 13)),
                        if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 11, color: Color(0xFF9AA3B8))),
                      ],
                    ),
                  ),
                  Text(NumberHelper.formatCurrency(diff),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: diff.abs() < 1 ? Colors.green : Colors.red)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
