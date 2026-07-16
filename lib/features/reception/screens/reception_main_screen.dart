import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import 'reception_home_screen.dart';
import 'subscription_operations_screen.dart';
import 'operations_screen.dart';
import 'customers_list_screen.dart';
import 'profile_settings_screen.dart';
import '../../../core/localization/app_strings.dart';

/// Front-desk console. The five workspaces keep their own screen chrome, so
/// the shell hides its topbar and just provides the sidebar navigation.
class ReceptionMainScreen extends StatefulWidget {
  const ReceptionMainScreen({super.key});

  @override
  State<ReceptionMainScreen> createState() => _ReceptionMainScreenState();
}

class _ReceptionMainScreenState extends State<ReceptionMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ReceptionHomeScreen(),
    SubscriptionOperationsScreen(),
    OperationsScreen(),
    CustomersListScreen(),
    ProfileSettingsScreen(),
  ];

  static List<String> get _titles => [S.home, S.subs, S.ops, S.clients, S.profile];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return DashboardShell(
      accent: Theme.of(context).colorScheme.primary,
      appTitle: 'PowerFit',
      roleTag: S.reception,
      userName: auth.username ?? S.reception,
      userRole: S.frontDesk,
      selectedIndex: _selectedIndex,
      onSelect: (i) => setState(() => _selectedIndex = i),
      pageTitle: _titles[_selectedIndex],
      onLogout: auth.logout,
      showTopbar: false,
      navItems: [
        DashNavItem(Icons.home_outlined, S.home),
        DashNavItem(Icons.card_membership_outlined, S.subs),
        DashNavItem(Icons.assignment_outlined, S.ops),
        DashNavItem(Icons.people_outline, S.clients),
        DashNavItem(Icons.person_outline, S.profile),
      ],
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
