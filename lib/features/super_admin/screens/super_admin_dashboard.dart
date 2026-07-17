import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/role_utils.dart';
import '../../../shared/models/owner_model.dart';
import '../../../shared/models/gym_model.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../providers/super_admin_provider.dart';
import 'create_gym_screen.dart';
import 'gym_detail_screen.dart';
import 'super_admin_settings_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<SuperAdminProvider>();

    final body = provider.isLoading
        ? const DashboardSkeleton()
        : provider.error != null
            ? ErrorDisplay(
                message: provider.error!,
                onRetry: () => provider.refresh(),
              )
            : _buildCurrentTab(context, provider);

    return DashboardShell(
      accent: Theme.of(context).colorScheme.primary,
      appTitle: 'PowerFit',
      roleTag: S.superAdmin,
      userName: authProvider.username ?? S.superAdmin,
      userRole: S.platformAdministrator,
      selectedIndex: _selectedIndex,
      onSelect: (i) => setState(() => _selectedIndex = i),
      pageTitle: _titles[_selectedIndex],
      pageSub: _selectedIndex == 0 ? S.platformOverview : null,
      navItems: [
        DashNavItem(Icons.dashboard_outlined, S.overview),
        DashNavItem(Icons.fitness_center_outlined, S.gyms),
        DashNavItem(Icons.manage_accounts_outlined, S.owners),
        DashNavItem(Icons.people_outline, S.allStaff),
      ],
      actions: [
        DashIconAction(
            icon: Icons.refresh, tooltip: S.refresh, onTap: () => provider.refresh()),
        DashIconAction(
          icon: Icons.settings_outlined,
          tooltip: S.settings,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SuperAdminSettingsScreen())),
        ),
      ],
      onLogout: authProvider.logout,
      floatingActionButton: _selectedIndex == 1 || _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGymScreen()),
                ).then((_) => provider.refresh());
              },
              icon: const Icon(Icons.person_add),
              label: Text(S.newOwner),
            )
          : null,
      body: body,
    );
  }

  static List<String> get _titles =>
      [S.platformAdmin, S.gyms, S.owners, S.allStaff];

  Widget _buildCurrentTab(
      BuildContext context, SuperAdminProvider provider) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context, provider);
      case 1:
        return _buildGymsTab(context, provider);
      case 2:
        return _buildOwnersTab(context, provider);
      case 3:
        return _buildStaffTab(context, provider);
      default:
        return _buildOverviewTab(context, provider);
    }
  }

  // ─── GYMS ────────────────────────────────────────────────────────────

  Widget _buildGymsTab(BuildContext context, SuperAdminProvider provider) {
    if (provider.gyms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center_outlined,
                size: 80, color: Color(0xFF6B7590)),
            const SizedBox(height: 24),
            Text(
              S.noGymsYet,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: const Color(0xFF9AA3B8)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: provider.gyms.length,
        itemBuilder: (context, index) =>
            _buildGymCard(context, provider.gyms[index], provider),
      ),
    );
  }

  Widget _buildGymCard(
      BuildContext context, GymModel gym, SuperAdminProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GymDetailScreen(gym: gym)),
          ).then((_) => provider.refresh());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                child: Icon(Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            gym.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gym.isActive
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gym.isActive ? S.active : S.inactive,
                            style: TextStyle(
                              color: gym.isActive ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (gym.ownerName != null)
                      Text(
                        gym.ownerName!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9AA3B8)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _gymStatChip(Icons.store, '${gym.branchCount}'),
                        const SizedBox(width: 10),
                        _gymStatChip(Icons.people, '${gym.customerCount}'),
                        const SizedBox(width: 10),
                        _gymStatChip(Icons.badge, '${gym.staffCount}'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'toggle') {
                    final result = await provider.toggleGymStatus(gym);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['success'] == true
                              ? (result['active'] == true
                                  ? S.gymActivated
                                  : S.gymDeactivated)
                              : result['message'].toString()),
                          backgroundColor: result['success'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          gym.isActive ? Icons.block : Icons.check_circle,
                          color: gym.isActive ? Colors.red : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(gym.isActive ? S.deactivate : S.activate),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gymStatChip(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9AA3B8)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7590))),
      ],
    );
  }

  // ─── ALL STAFF ───────────────────────────────────────────────────────

  Widget _buildStaffTab(BuildContext context, SuperAdminProvider provider) {
    final staff = provider.allStaff;
    if (staff.isEmpty) {
      return Center(
        child: Text(S.noStaffFound,
            style: const TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: staff.length,
        itemBuilder: (context, index) {
          final member = staff[index];
          final name =
              member['full_name'] ?? member['username'] ?? S.unknown;
          final role = member['role']?.toString();
          final branchName = member['branch_name'] ?? '';
          final isActive = member['is_active'] ?? true;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Text(
                  name.toString().isNotEmpty
                      ? name.toString()[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  RoleUtils.getRoleDisplayName(role),
                  if (branchName.toString().isNotEmpty) branchName.toString(),
                ].join(' · '),
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF9AA3B8)),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? S.active : S.inactive,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.red),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
      BuildContext context, SuperAdminProvider provider) {
    return DashBody(
      onRefresh: () => provider.refresh(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.platformAdministration,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.createManageOwners,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Color(0xFF9AA3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            S.platformOverview,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          DashKpiGrid(cards: [
            DashKpiCard(
              label: S.totalGyms,
              value: '${provider.totalGyms}',
              icon: Icons.fitness_center,
              iconColor: const Color(0xFFF59E0B),
            ),
            DashKpiCard(
              label: S.activeGyms,
              value: '${provider.activeGyms}',
              icon: Icons.check_circle,
              iconColor: const Color(0xFF10B981),
              valueColor: const Color(0xFF10B981),
            ),
            DashKpiCard(
              label: S.totalBranches,
              value: '${provider.totalBranches}',
              icon: Icons.store,
              iconColor: const Color(0xFF3B82F6),
            ),
            DashKpiCard(
              label: S.totalCustomers,
              value: '${provider.totalCustomers}',
              icon: Icons.people,
              iconColor: const Color(0xFF8B5CF6),
            ),
            DashKpiCard(
              label: S.totalStaff,
              value: '${provider.totalStaff}',
              icon: Icons.badge,
              iconColor: const Color(0xFF14B8A6),
            ),
            DashKpiCard(
              label: S.totalOwners,
              value: '${provider.totalOwners}',
              icon: Icons.manage_accounts,
              iconColor: const Color(0xFFF97316),
            ),
          ]),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.recentOwners,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 2),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(S.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (provider.owners.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.manage_accounts_outlined,
                        size: 64, color: Color(0xFF6B7590)),
                    const SizedBox(height: 16),
                    Text(
                      S.noOwnersYet,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Color(0xFF9AA3B8)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.createFirstOwner,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Color(0xFF6B7590)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.owners
                .take(5)
                .map((owner) => _buildOwnerCard(context, owner, provider)),
        ],
      ),
    );
  }

  Widget _buildOwnersTab(
      BuildContext context, SuperAdminProvider provider) {
    if (provider.owners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_accounts_outlined,
                size: 80, color: Color(0xFF6B7590)),
            const SizedBox(height: 24),
            Text(
              S.noOwnersYetTab,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Color(0xFF9AA3B8)),
            ),
            const SizedBox(height: 8),
            Text(
              S.tapPlusToCreate,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Color(0xFF6B7590)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: provider.owners.length,
      itemBuilder: (context, index) =>
          _buildOwnerCard(context, provider.owners[index], provider),
    );
  }

  /// Tapping an owner opens their gym — the drill-down path the platform
  /// admin actually uses: owner → gym (branches) → branch data.
  void _openOwnerGym(
      BuildContext context, OwnerModel owner, SuperAdminProvider provider) {
    GymModel? gym;
    for (final candidate in provider.gyms) {
      if (candidate.ownerId == owner.id) {
        gym = candidate;
        break;
      }
    }
    if (gym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.noGymForOwner), backgroundColor: Colors.orange),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymDetailScreen(gym: gym!)),
    ).then((_) => provider.refresh());
  }

  Widget _buildOwnerCard(
      BuildContext context, OwnerModel owner, SuperAdminProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openOwnerGym(context, owner, provider),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.15),
              child: Text(
                owner.fullName.isNotEmpty
                    ? owner.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          owner.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: owner.isActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          owner.isActive ? S.active : S.inactive,
                          style: TextStyle(
                            color:
                                owner.isActive ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${owner.username}',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF9AA3B8)),
                  ),
                  if (owner.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      owner.email!,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF6B7590)),
                    ),
                  ],
                  if (owner.lastLogin != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: Color(0xFF9AA3B8)),
                        const SizedBox(width: 4),
                        Text(
                          S.lastLogin(_formatDate(owner.lastLogin!)),
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF9AA3B8)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Toggle active button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'toggle') {
                  final result =
                      await provider.toggleOwnerStatus(owner.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] as String),
                        backgroundColor: result['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        owner.isActive
                            ? Icons.block
                            : Icons.check_circle,
                        color: owner.isActive ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                          owner.isActive ? S.deactivate : S.activate),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return S.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return S.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return S.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}
