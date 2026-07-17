import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/role_utils.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Full drill-down into any branch of any gym, for the super admin.
///
/// Deliberately self-contained on [ApiService]: the standalone admin app
/// doesn't carry the staff-side providers (ReceptionProvider etc.), so this
/// screen fetches and renders everything itself — headline stats, the member
/// roster and the staff list.
class SuperAdminBranchDetailScreen extends StatefulWidget {
  final int branchId;
  final String branchName;

  const SuperAdminBranchDetailScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<SuperAdminBranchDetailScreen> createState() =>
      _SuperAdminBranchDetailScreenState();
}

class _SuperAdminBranchDetailScreenState
    extends State<SuperAdminBranchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _performance = {};
  List<Map<String, dynamic>> _members = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = context.read<ApiService>();
    try {
      final responses = await Future.wait([
        api.get('/api/branches/${widget.branchId}/performance'),
        api.get('/api/customers',
            queryParameters: {'branch_id': widget.branchId, 'per_page': 200}),
      ]);

      final perfRaw = responses[0].data;
      final perf = perfRaw is Map && perfRaw.containsKey('data')
          ? perfRaw['data']
          : perfRaw;

      final custRaw = responses[1].data;
      final custData = custRaw is Map ? (custRaw['data'] ?? custRaw) : custRaw;
      List<dynamic> customers = [];
      if (custData is Map) {
        customers = List<dynamic>.from(custData['items'] ?? []);
      } else if (custData is List) {
        customers = custData;
      }

      setState(() {
        _performance = perf is Map<String, dynamic> ? perf : {};
        _members = customers
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: S.overview),
            Tab(text: S.members),
            Tab(text: S.staff),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: Text(S.retry)),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMembersTab(),
                    _buildStaffTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final accent = Theme.of(context).colorScheme.primary;
    final data = _performance;
    final revenue = (data['total_revenue'] ?? 0).toDouble();
    final openComplaints = data['open_complaints'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashKpiGrid(cards: [
            DashKpiCard(
                label: S.totalRevenue,
                value: NumberHelper.formatCurrency(revenue),
                icon: Icons.attach_money,
                iconColor: accent),
            DashKpiCard(
                label: S.totalCustomers,
                value: '${data['total_customers'] ?? _members.length}',
                icon: Icons.people,
                iconColor: DashColors.blue),
            DashKpiCard(
                label: S.activeSubs,
                value: '${data['active_subscriptions'] ?? 0}',
                icon: Icons.card_membership,
                iconColor: DashColors.emerald,
                valueColor: DashColors.emerald),
            DashKpiCard(
                label: S.checkInsThisMonth,
                value: '${data['check_ins_count'] ?? 0}',
                icon: Icons.login,
                iconColor: DashColors.amber),
            DashKpiCard(
                label: S.newCustomers,
                value: '${data['new_customers'] ?? 0}',
                icon: Icons.person_add,
                iconColor: DashColors.blue),
            DashKpiCard(
                label: S.openComplaints,
                value: '$openComplaints',
                icon: Icons.report_problem,
                iconColor:
                    openComplaints > 0 ? Colors.red : DashColors.emerald),
          ]),
          const SizedBox(height: 20),
          DashSectionCard(
            title: S.dailyOperations,
            accent: accent,
            child: Column(
              children: [
                _infoRow(S.expiredThisMonth,
                    '${data['expired_subscriptions'] ?? 0}'),
                const Divider(height: 20),
                _infoRow(S.frozenSubscriptions,
                    '${data['frozen_subscriptions'] ?? 0}'),
                const Divider(height: 20),
                _infoRow(S.complaints, '${data['complaints_count'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = _filteredMembers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
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
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Text(S.noCustomersFound,
                      style: const TextStyle(color: Color(0xFF9AA3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final name = (member['full_name'] ?? S.unknown).toString();
                    final phone = (member['phone'] ?? '').toString();
                    final hasActive =
                        member['has_active_subscription'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _showMemberSheet(member),
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
      ],
    );
  }

  void _showMemberSheet(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (member['full_name'] ?? S.unknown).toString(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _infoRow(S.phone, (member['phone'] ?? S.na).toString()),
            const Divider(height: 20),
            _infoRow(S.email, (member['email'] ?? S.na).toString()),
            const Divider(height: 20),
            _infoRow(
                S.status,
                member['has_active_subscription'] == true
                    ? S.active
                    : S.inactive),
            if (member['created_at'] != null) ...[
              const Divider(height: 20),
              _infoRow(S.created,
                  member['created_at'].toString().split('T').first),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab() {
    final staff = List<dynamic>.from(_performance['staff_performance'] ?? []);

    if (staff.isEmpty) {
      return Center(
        child: Text(S.noStaffFound,
            style: const TextStyle(color: Color(0xFF9AA3B8))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final member = staff[index];
        final name = (member['full_name'] ?? member['staff_name'] ?? S.unknown)
            .toString();
        final role = member['role']?.toString();
        final isActive = member['is_active'] ?? true;
        final revenue = (member['total_revenue'] ?? 0).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              RoleUtils.getRoleDisplayName(role),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B8)),
            ),
            trailing: revenue > 0
                ? Text(
                    NumberHelper.formatCurrency(revenue),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
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
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
