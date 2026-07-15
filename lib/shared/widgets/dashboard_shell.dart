import 'package:flutter/material.dart';

/// Shared design tokens for the PowerFit staff console (desktop-sidebar layout).
/// Neutrals follow the charcoal-navy instrument-panel system introduced on the
/// landing page; role/gym accent colors arrive via [DashboardShell.accent] and
/// are untouched by these platform surfaces.
class DashColors {
  static const bg = Color(0xFF0E1425);
  static const sidebar = Color(0xFF0A0F1D);
  static const topbar = Color(0xFF131C33);
  static const card = Color(0xFF16203A);
  static const inner = Color(0xFF111B33);
  static const muted = Color(0xFF9AA3B8);
  static const subtle = Color(0xFF6B7590);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF4C6FFF);
  static const line = Color(0xFF243050);
}

class DashNavItem {
  final IconData icon;
  final String label;
  const DashNavItem(this.icon, this.label);
}

/// Responsive console shell: a fixed sidebar + sticky topbar on wide screens,
/// collapsing to a hamburger drawer on narrow ones. The [body] is the current
/// tab's content; [selectedIndex]/[onSelect] drive tab switching.
class DashboardShell extends StatelessWidget {
  final Color accent;
  final String appTitle;
  final String roleTag;
  final String userName;
  final String userRole;
  final List<DashNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String pageTitle;
  final String? pageSub;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;

  /// When false, the shell renders no topbar (the [body] provides its own
  /// chrome, e.g. child screens with their own AppBars). A slim menu strip is
  /// still shown on narrow screens so the drawer stays reachable.
  final bool showTopbar;

  const DashboardShell({
    super.key,
    required this.accent,
    required this.appTitle,
    required this.roleTag,
    required this.userName,
    required this.userRole,
    required this.navItems,
    required this.selectedIndex,
    required this.onSelect,
    required this.pageTitle,
    this.pageSub,
    this.actions = const [],
    required this.body,
    this.floatingActionButton,
    this.showTopbar = true,
  });

  static const double _wideBreakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    if (wide) {
      return Scaffold(
        backgroundColor: DashColors.bg,
        floatingActionButton: floatingActionButton,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              accent: accent,
              appTitle: appTitle,
              roleTag: roleTag,
              userName: userName,
              userRole: userRole,
              navItems: navItems,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
            ),
            Expanded(
              child: showTopbar
                  ? Column(
                      children: [
                        _Topbar(
                          pageTitle: pageTitle,
                          pageSub: pageSub,
                          actions: actions,
                          showMenu: false,
                        ),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: DashColors.bg,
      floatingActionButton: floatingActionButton,
      drawer: Drawer(
        backgroundColor: DashColors.sidebar,
        child: _Sidebar(
          accent: accent,
          appTitle: appTitle,
          roleTag: roleTag,
          userName: userName,
          userRole: userRole,
          navItems: navItems,
          selectedIndex: selectedIndex,
          onSelect: (i) {
            Navigator.of(context).pop();
            onSelect(i);
          },
          inDrawer: true,
        ),
      ),
      body: Column(
        children: [
          if (showTopbar)
            _Topbar(
              pageTitle: pageTitle,
              pageSub: pageSub,
              actions: actions,
              showMenu: true,
            )
          else
            SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final Color accent;
  final String appTitle;
  final String roleTag;
  final String userName;
  final String userRole;
  final List<DashNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool inDrawer;

  const _Sidebar({
    required this.accent,
    required this.appTitle,
    required this.roleTag,
    required this.userName,
    required this.userRole,
    required this.navItems,
    required this.selectedIndex,
    required this.onSelect,
    this.inDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName.characters.first : '?';
    return Container(
      width: 250,
      color: DashColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  _logoMark(accent, 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          roleTag,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: DashColors.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                children: [
                  for (var i = 0; i < navItems.length; i++)
                    _navTile(
                      navItems[i],
                      i == selectedIndex,
                      () => onSelect(i),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: DashColors.line),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
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
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          userRole,
                          style: const TextStyle(
                            color: DashColors.subtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _navTile(DashNavItem item, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: BorderDirectional(
                start: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? Colors.white : DashColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : DashColors.muted,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  final String pageTitle;
  final String? pageSub;
  final List<Widget> actions;
  final bool showMenu;

  const _Topbar({
    required this.pageTitle,
    required this.pageSub,
    required this.actions,
    required this.showMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DashColors.bg,
        border: Border(bottom: BorderSide(color: DashColors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(showMenu ? 8 : 28, 14, 20, 14),
          child: Row(
            children: [
              if (showMenu)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (pageSub != null)
                      Text(
                        pageSub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DashColors.subtle,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// A KPI stat card in the console style.
class DashKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final String? sub;
  final String? trend;
  final bool trendUp;

  const DashKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
    this.sub,
    this.trend,
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashColors.card,
        border: Border.all(color: DashColors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (trend != null || sub != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (trend != null) ...[
                  Icon(
                    trendUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: trendUp ? DashColors.emerald : Colors.redAccent,
                    size: 18,
                  ),
                  Text(
                    trend!,
                    style: TextStyle(
                      color: trendUp ? DashColors.emerald : Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (sub != null)
                  Flexible(
                    child: Text(
                      sub!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DashColors.subtle,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled section card with an optional trailing action link.
class DashSectionCard extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final Widget child;

  const DashSectionCard({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DashColors.card,
        border: Border.all(color: DashColors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (actionLabel != null)
                InkWell(
                  onTap: onAction,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// A simple vertical bar chart. [bars] are 0..1 fractions with labels.
class DashBarChart extends StatelessWidget {
  final List<double> bars;
  final List<String> labels;
  final Color accent;
  final double height;

  const DashBarChart({
    super.key,
    required this.bars,
    required this.labels,
    required this.accent,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = bars.isEmpty ? 1.0 : bars.reduce((a, b) => a > b ? a : b);
    final peak = maxV <= 0 ? 1.0 : maxV;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bars.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (bars[i] / peak).clamp(0.04, 1.0),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 44),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: i == bars.length - 1
                                    ? [
                                        const Color(0xFFEF4444),
                                        const Color(0xFF991B1B),
                                      ]
                                    : [accent, accent.withValues(alpha: 0.45)],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i < labels.length ? labels[i] : '',
                      style: TextStyle(
                        color: i == bars.length - 1
                            ? Colors.white
                            : DashColors.subtle,
                        fontSize: 12,
                        fontWeight: i == bars.length - 1
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// An alert row with a colored leading dot and start border.
class DashAlertTile extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const DashAlertTile({
    super.key,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DashColors.inner,
          borderRadius: BorderRadius.circular(12),
          border: BorderDirectional(start: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DashColors.muted,
                        fontSize: 12,
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
}

/// A labelled progress bar row (branch comparison, targets, etc.).
class DashProgressRow extends StatelessWidget {
  final String name;
  final String trailing;
  final Color trailingColor;
  final double fraction;
  final Color accent;

  const DashProgressRow({
    super.key,
    required this.name,
    required this.trailing,
    required this.fraction,
    required this.accent,
    this.trailingColor = DashColors.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              trailing,
              style: TextStyle(color: trailingColor, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: DashColors.inner,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ],
    );
  }
}

/// A padded, scrollable body wrapper with the console's max content width.
class DashBody extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const DashBody({super.key, required this.child, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
    if (onRefresh == null) return content;
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: onRefresh!,
      child: content,
    );
  }
}

/// Responsive KPI grid: [columns] cards per row on wide, fewer on narrow.
class DashKpiGrid extends StatelessWidget {
  final List<Widget> cards;
  const DashKpiGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 1000 ? 4 : (w >= 640 ? 2 : 1);
    const gap = 18.0;
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += cols) {
      final row = <Widget>[];
      for (var j = 0; j < cols; j++) {
        final idx = i + j;
        row.add(
          Expanded(child: idx < cards.length ? cards[idx] : const SizedBox()),
        );
        if (j < cols - 1) row.add(const SizedBox(width: gap));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: row,
          ),
        ),
      );
      if (i + cols < cards.length) rows.add(const SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}

Widget _logoMark(Color accent, double size) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(size * 0.28),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.5),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.28),
    child: Image.asset('assets/icon/powerfit.jpeg', fit: BoxFit.cover),
  ),
);

/// A compact icon action button for the topbar.
class DashIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool badge;

  const DashIconAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: DashColors.topbar,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: DashColors.muted, size: 19),
            if (badge)
              PositionedDirectional(
                top: 9,
                end: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    border: Border.all(color: DashColors.topbar, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 10),
      child: tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn,
    );
  }
}
