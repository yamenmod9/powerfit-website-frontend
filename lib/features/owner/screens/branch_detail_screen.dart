import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/models/customer_model.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/localization/app_strings.dart';
import '../../reception/screens/customer_detail_screen.dart';

/// Full drill-down into one branch, opened from the owner's and regional
/// manager's branch lists. Everything the branch holds is reachable from
/// here: headline numbers, the member roster (tap-through to the same
/// customer detail the front desk uses), revenue by service, staff and
/// daily operations.
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

class _BranchDetailScreenState extends State<BranchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _branchData;
  String? _error;

  // Members tab
  List<Map<String, dynamic>> _members = [];
  bool _membersLoading = true;
  final _memberSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBranchData();
    _loadMembers();
    _memberSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberSearchController.dispose();
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

  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get(
        ApiEndpoints.customers,
        queryParameters: {'branch_id': widget.branchId, 'per_page': 200},
      );
      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;
        List<dynamic> raw = [];
        if (d is Map) {
          raw = List<dynamic>.from(d['items'] ?? []);
        } else if (d is List) {
          raw = d;
        }
        setState(() {
          _members = raw
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          _membersLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Branch members failed: $e');
    }
    if (mounted) setState(() => _membersLoading = false);
  }

  List<Map<String, dynamic>> get _filteredMembers {
    final query = _memberSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return _members;
    return _members.where((m) {
      final name = (m['full_name'] ?? '').toString().toLowerCase();
      final phone = (m['phone'] ?? '').toString();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branchName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBranchData();
              _loadMembers();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: S.overview),
            Tab(text: S.members),
            Tab(text: S.revenue),
            Tab(text: S.staff),
            Tab(text: S.operations),
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
                          child: Text(S.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMembersTab(),
                    _buildRevenueTab(),
                    _buildStaffTab(),
                    _buildOperationsTab(),
                  ],
                ),
    );
  }

  // ─── OVERVIEW ────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final data = _branchData ?? {};
    final accent = Theme.of(context).colorScheme.primary;
    final totalRevenue = (data['total_revenue'] ?? 0).toDouble();
    final totalCustomers = data['total_customers'] ?? 0;
    final activeSubscriptions = data['active_subscriptions'] ?? 0;
    final checkIns = data['check_ins_count'] ?? 0;
    final newCustomers = data['new_customers'] ?? 0;
    final openComplaints = data['open_complaints'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                iconColor: DashColors.blue),
            DashKpiCard(
                label: S.activeSubs,
                value: NumberHelper.formatNumber(activeSubscriptions),
                icon: Icons.card_membership,
                iconColor: DashColors.emerald,
                valueColor: DashColors.emerald),
            DashKpiCard(
                label: S.checkInsThisMonth,
                value: NumberHelper.formatNumber(checkIns),
                icon: Icons.login,
                iconColor: DashColors.amber),
            DashKpiCard(
                label: S.newCustomers,
                value: NumberHelper.formatNumber(newCustomers),
                icon: Icons.person_add,
                iconColor: DashColors.blue),
            DashKpiCard(
                label: S.openComplaints,
                value: NumberHelper.formatNumber(openComplaints),
                icon: Icons.report_problem,
                iconColor: openComplaints > 0 ? Colors.red : DashColors.emerald),
          ]),
          const SizedBox(height: 20),
          DashSectionCard(
            title: S.branchInformation,
            accent: accent,
            child: Column(
              children: [
                _buildInfoRow(S.branchId, '#${widget.branchId}'),
                const Divider(height: 20),
                _buildInfoRow(S.branchName, widget.branchName),
                const Divider(height: 20),
                _buildInfoRow(S.status, data['status'] ?? S.active),
                if (data['address'] != null) ...[
                  const Divider(height: 20),
                  _buildInfoRow(S.address, data['address']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MEMBERS ─────────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    if (_membersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final members = _filteredMembers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _memberSearchController,
            decoration: InputDecoration(
              hintText: S.searchCustomers,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${members.length} / ${_members.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B8)),
            ),
          ),
        ),
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Text(S.noCustomersFound,
                      style: const TextStyle(color: Color(0xFF9AA3B8))))
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final name = (member['full_name'] ?? S.unknown).toString();
                      final phone = (member['phone'] ?? '').toString();
                      final hasActive = member['has_active_subscription'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(
                                  customer: CustomerModel.fromJson(member),
                                ),
                              ),
                            ).then((_) => _loadMembers());
                          },
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(phone,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9AA3B8))),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasActive
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasActive ? S.active : S.inactive,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      hasActive ? Colors.green : Colors.orange),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ─── REVENUE ─────────────────────────────────────────────────────────

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (revenueByService.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(S.noRevenueData)),
              ),
            )
          else
            ...revenueByService.map<Widget>((service) {
              final name = service['service_name'] ?? service['name'] ?? 'Unknown';
              final revenue = (service['revenue'] ?? 0).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.fitness_center,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(name),
                  trailing: Text(
                    NumberHelper.formatCurrency(revenue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── STAFF ───────────────────────────────────────────────────────────

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (staff.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(S.noStaffData)),
              ),
            )
          else
            ...staff.map<Widget>((member) {
              final name = member['staff_name'] ?? member['name'] ?? member['full_name'] ?? 'Unknown';
              final role = (member['role'] ?? 'Staff').toString().replaceAll('_', ' ');
              final isActive = member['is_active'] ?? true;
              final revenue = (member['total_revenue'] ?? 0).toDouble();
              final txCount = member['transactions_count'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    child: Text(name[0].toUpperCase()),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$role • ${S.txCount(txCount as int)}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: revenue > 0
                      ? Text(
                          NumberHelper.formatCurrency(revenue),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? S.active : S.inactive,
                            style: TextStyle(
                                fontSize: 11,
                                color: isActive ? Colors.green : Colors.red),
                          ),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── OPERATIONS ──────────────────────────────────────────────────────

  Widget _buildOperationsTab() {
    final data = _branchData ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DashSectionCard(
        title: S.dailyOperations,
        accent: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            _buildInfoRow(S.checkInsThisMonth, (data['check_ins_count'] ?? 0).toString()),
            const Divider(height: 20),
            _buildInfoRow(S.activeSubscriptions, (data['active_subscriptions'] ?? 0).toString()),
            const Divider(height: 20),
            _buildInfoRow(S.openComplaints, (data['open_complaints'] ?? 0).toString()),
            const Divider(height: 20),
            _buildInfoRow(S.expiredThisMonth, (data['expired_subscriptions'] ?? 0).toString()),
            const Divider(height: 20),
            _buildInfoRow(S.frozenSubscriptions, (data['frozen_subscriptions'] ?? 0).toString()),
            const Divider(height: 20),
            _buildInfoRow(S.newCustomers, (data['new_customers'] ?? 0).toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
