import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../core/utils/helpers.dart';
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<BranchManagerProvider>();
    final branding = context.watch<GymBrandingProvider>();
    final gymName = branding.isSetupComplete && branding.gymId != null
        ? branding.gymName
        : S.branchManagerTitle;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(gymName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDashboardData(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BranchManagerSettingsScreen(),
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
      body: provider.isLoading
          ? const LoadingIndicator(message: S.loadingDashboard)
          : provider.error != null
              ? ErrorDisplay(
                  message: provider.error!,
                  onRetry: () => provider.loadDashboardData(),
                )
              : _buildCurrentTab(context, provider, authProvider),
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
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard),
                    label: S.overview,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.people_outlined),
                    selectedIcon: const Icon(Icons.people),
                    label: S.staff,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.report_problem_outlined),
                    selectedIcon: const Icon(Icons.report_problem),
                    label: S.complaints,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context, BranchManagerProvider provider, AuthProvider authProvider) {
    if (_selectedIndex == 0) {
      return RefreshIndicator(
        onRefresh: () => provider.loadDashboardData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context, authProvider.username ?? 'Manager'),
              const SizedBox(height: 20),
              Text(
                S.performanceOverview,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(context, provider),
              const SizedBox(height: 24),
              // Could add charts or other widgets here
            ],
          ),
        ),
      );
    } else if (_selectedIndex == 1) {
      return _buildStaffTab(provider);
    } else {
      return _buildComplaintsTab(provider);
    }
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

  Widget _buildStatsGrid(BuildContext context, BranchManagerProvider provider) {
    final performance = provider.branchPerformance ?? {};
    final dailyOps = provider.dailyOperations ?? {};

    final todayRevenue = (dailyOps['total_revenue'] ?? performance['today_revenue'] ?? 0).toDouble();
    final activeMembers = performance['active_members'] ?? performance['active_subscriptions'] ?? 0;
    final totalCustomers = performance['total_customers'] ?? 0;
    final pendingComplaints = provider.complaints.where((c) =>
        c['status']?.toString().toLowerCase() == 'pending' ||
        c['status']?.toString().toLowerCase() == 'open').length;
    final expiringCount = performance['expiring_subscriptions'] ?? 0;
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
          title: S.todaysRevenue,
          value: NumberHelper.formatCurrency(todayRevenue),
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        StatCard(
          title: S.activeMembers,
          value: NumberHelper.formatNumber(activeMembers),
          icon: Icons.people,
          color: Colors.blue,
        ),
        StatCard(
          title: S.totalCustomers,
          value: NumberHelper.formatNumber(totalCustomers),
          icon: Icons.person,
          color: Colors.orange,
        ),
        StatCard(
          title: expiringCount > 0 ? S.expiringSoon(expiringCount) : S.pendingIssues,
          value: NumberHelper.formatNumber(expiringCount > 0 ? expiringCount : pendingComplaints),
          icon: expiringCount > 0 ? Icons.timer_off : Icons.report_problem,
          color: expiringCount > 0 ? Colors.deepOrange : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStaffTab(BranchManagerProvider provider) {
    final staffList = provider.staff;
    if (staffList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(S.noStaffFound, style: TextStyle(fontSize: 16, color: Colors.grey)),
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
              roleColor = Colors.grey;
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
                                child: const Text(S.inactive, style: TextStyle(fontSize: 11, color: Colors.red)),
                              ),
                            ],
                          ],
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email, size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ],
                    ),
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
      return const Center(child: Text(S.noComplaints));
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
