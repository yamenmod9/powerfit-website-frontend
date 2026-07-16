import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/models/owner_model.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../providers/super_admin_provider.dart';
import 'create_gym_screen.dart';
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
      pageTitle: _selectedIndex == 0 ? S.platformAdmin : S.owners,
      pageSub: _selectedIndex == 0 ? S.platformOverview : null,
      navItems: [
        DashNavItem(Icons.dashboard_outlined, S.overview),
        DashNavItem(Icons.manage_accounts_outlined, S.owners),
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
      floatingActionButton: _selectedIndex == 1
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

  Widget _buildCurrentTab(
      BuildContext context, SuperAdminProvider provider) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context, provider);
      case 1:
        return _buildOwnersTab(context, provider);
      default:
        return _buildOverviewTab(context, provider);
    }
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
              label: S.totalOwners,
              value: '${provider.totalOwners}',
              icon: Icons.manage_accounts,
              iconColor: const Color(0xFFF59E0B),
            ),
            DashKpiCard(
              label: S.activeOwners,
              value: '${provider.activeOwners}',
              icon: Icons.check_circle,
              iconColor: const Color(0xFF10B981),
              valueColor: const Color(0xFF10B981),
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
                onPressed: () => setState(() => _selectedIndex = 1),
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

  Widget _buildOwnerCard(
      BuildContext context, OwnerModel owner, SuperAdminProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
