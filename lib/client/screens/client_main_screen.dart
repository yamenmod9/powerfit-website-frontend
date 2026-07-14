import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../core/theme/client_theme.dart';
import 'client_overview_tab.dart';
import 'qr_screen.dart';
import 'entry_history_screen.dart';
import 'settings_screen.dart';

/// Bottom-tab shell for the member app. Four tabs matching the
/// PowerFit Member App design: Home, Check-in (QR), History, Profile.
/// The full SubscriptionScreen stays reachable from the Home subscription
/// card and the Profile "manage subscription" row, so no feature is lost.
class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    ClientOverviewTab(onGoToCheckIn: () => _select(1)),
    const QrScreen(),
    const EntryHistoryScreen(),
    const SettingsScreen(),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.darkGrey,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _MemberNavBar(
        selectedIndex: _selectedIndex,
        onSelect: _select,
      ),
    );
  }
}

class _MemberNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _MemberNavBar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(Icons.home_rounded, Icons.home_outlined, S.home),
      _NavItem(Icons.qr_code_rounded, Icons.qr_code_outlined, S.checkInNav),
      _NavItem(Icons.history_rounded, Icons.history_outlined, S.history),
      _NavItem(Icons.person_rounded, Icons.person_outline, S.profile),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: ClientTheme.mediumGrey,
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _buildTab(items[i], i == selectedIndex, () => onSelect(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(_NavItem item, bool selected, VoidCallback onTap) {
    final color = selected ? ClientTheme.primaryRed : const Color(0xFF6A6A6A);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? item.activeIcon : item.icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}
