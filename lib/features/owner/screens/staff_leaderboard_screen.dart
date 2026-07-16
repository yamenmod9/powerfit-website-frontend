import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../providers/owner_dashboard_provider.dart';

/// How the leaderboard is ordered. Every metric sorts descending — the whole
/// point of the screen is who is on top.
enum _StaffSort { revenue, transactions, retention, renewal }

class StaffLeaderboardScreen extends StatefulWidget {
  const StaffLeaderboardScreen({super.key});

  @override
  State<StaffLeaderboardScreen> createState() => _StaffLeaderboardScreenState();
}

class _StaffLeaderboardScreenState extends State<StaffLeaderboardScreen> {
  _StaffSort _sort = _StaffSort.revenue;

  String _sortLabel(_StaffSort sort) => switch (sort) {
        _StaffSort.revenue => S.sortByRevenue,
        _StaffSort.transactions => S.sortByTransactions,
        _StaffSort.retention => S.sortByRetention,
        _StaffSort.renewal => S.sortByRenewal,
      };

  /// The provider falls back to raw /api/users records when the report returns
  /// nothing, so every read here tolerates a leaner shape than
  /// /api/reports/employee-performance sends.
  static String _nameOf(dynamic employee) => (employee['full_name'] ??
          employee['staff_name'] ??
          employee['name'] ??
          employee['employee_name'] ??
          employee['username'] ??
          S.unknown)
      .toString();

  static double _revenueOf(dynamic employee) =>
      ((employee['total_revenue'] ?? employee['revenue'] ?? 0) as num).toDouble();

  static int _transactionsOf(dynamic employee) =>
      ((employee['transactions_count'] ?? 0) as num).toInt();

  /// Null when the backend had no basis for the rate — no sales to compute a
  /// renewal share from, or nobody signed up to retain. Rendered as an em-dash
  /// so "no data" never reads as a genuine 0%.
  static double? _rateOf(dynamic employee, String key) {
    final value = employee[key];
    return value == null ? null : (value as num).toDouble();
  }

  static String _formatRate(double? rate) =>
      rate == null ? '—' : '${rate.toStringAsFixed(1)}%';

  /// Descending, with "no data" pinned last instead of sorting as zero.
  static int _compareRates(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  List<dynamic> _sorted(List<dynamic> employees) {
    final list = List<dynamic>.from(employees);
    list.sort((a, b) => switch (_sort) {
          _StaffSort.revenue => _revenueOf(b).compareTo(_revenueOf(a)),
          _StaffSort.transactions =>
            _transactionsOf(b).compareTo(_transactionsOf(a)),
          _StaffSort.retention => _compareRates(
              _rateOf(a, 'retention_rate'), _rateOf(b, 'retention_rate')),
          _StaffSort.renewal =>
            _compareRates(_rateOf(a, 'renewal_rate'), _rateOf(b, 'renewal_rate')),
        });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: DashColors.bg,
      appBar: AppBar(
        backgroundColor: DashColors.topbar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(S.staffLeaderboard),
        actions: [
          PopupMenuButton<_StaffSort>(
            icon: const Icon(Icons.sort),
            tooltip: S.sortBy,
            color: DashColors.card,
            initialValue: _sort,
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (context) => [
              for (final sort in _StaffSort.values)
                PopupMenuItem(
                  value: sort,
                  child: Text(
                    _sortLabel(sort),
                    style: TextStyle(
                      color: sort == _sort ? accent : Colors.white,
                      fontWeight:
                          sort == _sort ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OwnerDashboardProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<OwnerDashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const DashboardSkeleton();

          if (provider.error != null) {
            return ErrorDisplay(
              message: provider.error!,
              onRetry: () => provider.refresh(),
            );
          }

          final employees = _sorted(provider.employeePerformance);
          if (employees.isEmpty) return _emptyState();

          final podium = employees.take(3).toList();

          return DashBody(
            onRefresh: provider.refresh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kpiStrip(employees),
                const SizedBox(height: 20),
                DashSectionCard(
                  title: S.topPerformers,
                  accent: accent,
                  child: Column(
                    children: [
                      for (var i = 0; i < podium.length; i++) ...[
                        _podiumTile(podium[i], i + 1),
                        if (i < podium.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                DashSectionCard(
                  title: S.allStaffMembers,
                  accent: accent,
                  child: Column(
                    children: [
                      for (var i = 0; i < employees.length; i++) ...[
                        _staffTile(employees[i], i + 1, accent),
                        if (i < employees.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpiStrip(List<dynamic> employees) {
    final totalRevenue =
        employees.fold<double>(0, (sum, e) => sum + _revenueOf(e));
    final totalTransactions =
        employees.fold<int>(0, (sum, e) => sum + _transactionsOf(e));
    final retentionRates = employees
        .map((e) => _rateOf(e, 'retention_rate'))
        .whereType<double>()
        .toList();
    final avgRetention = retentionRates.isEmpty
        ? null
        : retentionRates.reduce((a, b) => a + b) / retentionRates.length;

    return DashKpiGrid(cards: [
      DashKpiCard(
        label: S.staff,
        value: '${employees.length}',
        icon: Icons.groups,
        iconColor: DashColors.blue,
      ),
      DashKpiCard(
        label: S.totalRevenue,
        value: NumberHelper.formatCurrency(totalRevenue),
        icon: Icons.payments,
        iconColor: DashColors.emerald,
        valueColor: DashColors.emerald,
      ),
      DashKpiCard(
        label: S.transactions,
        value: '$totalTransactions',
        icon: Icons.receipt_long,
        iconColor: DashColors.amber,
      ),
      DashKpiCard(
        label: S.avgRetention,
        value: _formatRate(avgRetention),
        icon: Icons.favorite,
        iconColor: Colors.purpleAccent,
      ),
    ]);
  }

  Widget _podiumTile(dynamic employee, int rank) {
    final (medalColor, medalIcon) = switch (rank) {
      1 => (DashColors.amber, Icons.looks_one),
      2 => (DashColors.muted, Icons.looks_two),
      _ => (const Color(0xFFB07A4B), Icons.looks_3),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashColors.inner,
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(start: BorderSide(color: medalColor, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(medalIcon, color: medalColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameOf(employee),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  S.transactionsCount(_transactionsOf(employee)),
                  style: const TextStyle(
                    color: DashColors.subtle,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            NumberHelper.formatCurrency(_revenueOf(employee)),
            style: const TextStyle(
              color: DashColors.emerald,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffTile(dynamic employee, int rank, Color accent) {
    final role = (employee['role'] ?? employee['position'] ?? '').toString();
    final branch = (employee['branch_name'] ?? employee['branch'] ?? '').toString();
    final signed = ((employee['customers_signed'] ?? 0) as num).toInt();

    // Signups are retention's denominator, so showing them next to the rate
    // keeps a lone "100%" from looking better than it is.
    final meta = [
      if (role.isNotEmpty) role,
      if (branch.isNotEmpty) branch,
      if (signed > 0) S.membersSignedCount(signed),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashColors.inner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameOf(employee),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashColors.subtle,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                NumberHelper.formatCurrency(_revenueOf(employee)),
                style: const TextStyle(
                  color: DashColors.emerald,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _metricChip(
                Icons.receipt_long,
                S.transactions,
                '${_transactionsOf(employee)}',
                DashColors.amber,
              ),
              const SizedBox(width: 8),
              _metricChip(
                Icons.favorite,
                S.retention,
                _formatRate(_rateOf(employee, 'retention_rate')),
                Colors.purpleAccent,
              ),
              const SizedBox(width: 8),
              _metricChip(
                Icons.autorenew,
                S.renewal,
                _formatRate(_rateOf(employee, 'renewal_rate')),
                DashColors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DashColors.subtle,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined,
              size: 44, color: DashColors.subtle),
          const SizedBox(height: 12),
          Text(
            S.noPerformanceData,
            style: const TextStyle(color: DashColors.subtle, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
