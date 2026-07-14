import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/localization/app_strings.dart';

class BranchDetailScreen extends StatefulWidget {
  final int branchId;
  final String branchName;

  const BranchDetailScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _branchData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBranchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBranchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get(
        ApiEndpoints.branchPerformance(widget.branchId),
      );

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        setState(() {
          _branchData = raw is Map<String, dynamic> ? raw : {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = S.failedToLoadBranch;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branchName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBranchData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: S.overview, icon: Icon(Icons.dashboard)),
            Tab(text: S.revenue, icon: Icon(Icons.attach_money)),
            Tab(text: S.staff, icon: Icon(Icons.people)),
            Tab(text: S.operations, icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const DashboardSkeleton()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBranchData,
                          child: const Text(S.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildRevenueTab(),
                    _buildStaffTab(),
                    _buildOperationsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final data = _branchData ?? {};
    final totalRevenue = (data['total_revenue'] ?? 0).toDouble();
    final totalCustomers = data['total_customers'] ?? 0;
    final activeSubscriptions = data['active_subscriptions'] ?? 0;
    final capacity = data['capacity'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                title: S.totalRevenue,
                value: NumberHelper.formatCurrency(totalRevenue),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              StatCard(
                title: S.totalCustomers,
                value: NumberHelper.formatNumber(totalCustomers),
                icon: Icons.people,
                color: Colors.blue,
              ),
              StatCard(
                title: S.activeSubscriptions,
                value: NumberHelper.formatNumber(activeSubscriptions),
                icon: Icons.card_membership,
                color: Colors.purple,
              ),
              StatCard(
                title: S.capacity,
                value: NumberHelper.formatNumber(capacity),
                icon: Icons.fitness_center,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Additional Info
          Text(
            S.branchInformation,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(S.branchId, '#${widget.branchId}'),
                  const Divider(),
                  _buildInfoRow(S.branchName, widget.branchName),
                  const Divider(),
                  _buildInfoRow(S.status, data['status'] ?? S.active),
                  if (data['address'] != null) ...[
                    const Divider(),
                    _buildInfoRow(S.address, data['address']),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    final data = _branchData ?? {};
    final rawRevenue = data['revenue_by_service'];

    // Convert to list: backend may return a dict {serviceName: amount} or a list
    List<Map<String, dynamic>> revenueByService = [];
    if (rawRevenue is Map) {
      rawRevenue.forEach((key, value) {
        revenueByService.add({
          'service_name': key,
          'revenue': value,
        });
      });
    } else if (rawRevenue is List) {
      revenueByService = List<Map<String, dynamic>>.from(rawRevenue);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.revenueByService,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (revenueByService.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text(S.noRevenueData)),
              ),
            )
          else
            ...revenueByService.map<Widget>((service) {
              final name = service['service_name'] ?? service['name'] ?? 'Unknown';
              final revenue = (service['revenue'] ?? 0).toDouble();
              final customers = service['customers'] ?? service['customer_count'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(name),
                  subtitle: Text(S.customersCount(customers as int)),
                  trailing: Text(
                    NumberHelper.formatCurrency(revenue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStaffTab() {
    final data = _branchData ?? {};
    final staff = data['staff_performance'] ?? data['staff'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.branchStaff,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (staff.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text(S.noStaffData)),
              ),
            )
          else
            ...staff.map<Widget>((member) {
              final name = member['staff_name'] ?? member['name'] ?? member['full_name'] ?? 'Unknown';
              final role = member['role'] ?? 'Staff';
              final isActive = member['is_active'] ?? true;
              final revenue = (member['total_revenue'] ?? 0).toDouble();
              final txCount = member['transactions_count'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name[0].toUpperCase()),
                  ),
                  title: Text(name),
                  subtitle: Text('$role • ${S.txCount(txCount as int)}'),
                  trailing: revenue > 0
                      ? Text(
                          NumberHelper.formatCurrency(revenue),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      : Chip(
                          label: Text(isActive ? S.active : S.inactive),
                          backgroundColor: isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOperationsTab() {
    final data = _branchData ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.dailyOperations,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(S.checkInsThisMonth, (data['check_ins_count'] ?? 0).toString()),
                  const Divider(),
                  _buildInfoRow(S.activeSubscriptions, (data['active_subscriptions'] ?? 0).toString()),
                  const Divider(),
                  _buildInfoRow(S.openComplaints, (data['open_complaints'] ?? 0).toString()),
                  const Divider(),
                  _buildInfoRow(S.expiredThisMonth, (data['expired_subscriptions'] ?? 0).toString()),
                  const Divider(),
                  _buildInfoRow(S.frozenSubscriptions, (data['frozen_subscriptions'] ?? 0).toString()),
                  const Divider(),
                  _buildInfoRow(S.newCustomers, (data['new_customers'] ?? 0).toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
