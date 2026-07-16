import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_frontend/shared/widgets/dashboard_shell.dart';

/// Groups KPI tiles into visual rows by their vertical offset.
List<List<Rect>> _rows(WidgetTester tester) {
  final rects = tester
      .widgetList<DashKpiCard>(find.byType(DashKpiCard))
      .map((card) => tester.getRect(find.byWidget(card)))
      .toList();

  final byTop = <double, List<Rect>>{};
  for (final rect in rects) {
    byTop.putIfAbsent(rect.top, () => []).add(rect);
  }
  final tops = byTop.keys.toList()..sort();
  return [for (final top in tops) byTop[top]!];
}

Widget _grid({required double width, int cards = 4}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: DashKpiGrid(
            cards: [
              for (var i = 0; i < cards; i++)
                DashKpiCard(
                  label: 'Metric $i',
                  value: '$i',
                  icon: Icons.people,
                  iconColor: DashColors.blue,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DashKpiGrid', () {
    testWidgets('packs two tiles per row on a phone-width column',
        (tester) async {
      // A 390pt phone minus the 24pt DashBody padding on each side.
      await tester.pumpWidget(_grid(width: 342));

      final rows = _rows(tester);
      expect(rows.length, 2, reason: '4 cards at 2-up should make 2 rows');
      expect(rows[0].length, 2);
      expect(rows[1].length, 2);
    });

    testWidgets('packs four tiles across on a desktop-width column',
        (tester) async {
      await tester.pumpWidget(_grid(width: 1132));

      final rows = _rows(tester);
      expect(rows.length, 1, reason: '4 cards should fit one desktop row');
      expect(rows.first.length, 4);
    });

    testWidgets('keeps the strip short — tiles are a fixed compact height',
        (tester) async {
      await tester.pumpWidget(_grid(width: 1132));

      final tile = tester.getRect(find.byType(DashKpiCard).first);
      expect(tile.height, 96);
    });

    testWidgets('never stretches fewer cards than columns across the row',
        (tester) async {
      await tester.pumpWidget(_grid(width: 1132, cards: 2));

      final rows = _rows(tester);
      expect(rows.length, 1);
      // Two cards must not each take a quarter-width slot's worth of stretch:
      // they split the row evenly instead.
      expect(rows.first.length, 2);
      expect(rows.first[0].width, closeTo(rows.first[1].width, 0.5));
    });

    testWidgets('balances the last row instead of leaving it half empty',
        (tester) async {
      // The accountant overview has 6 KPIs: 3+3 reads better than 4+2.
      await tester.pumpWidget(_grid(width: 1132, cards: 6));

      final rows = _rows(tester);
      expect(rows.length, 2);
      expect(rows[0].length, 3);
      expect(rows[1].length, 3);
    });

    testWidgets('leaves room beside the strip rather than filling the fold',
        (tester) async {
      await tester.pumpWidget(_grid(width: 342));

      // 2 rows of 96 + one 12pt gap.
      final height = tester.getSize(find.byType(DashKpiGrid)).height;
      expect(height, 204);
    });
  });

  group('DashboardShell logout', () {
    Widget shell({VoidCallback? onLogout}) => MaterialApp(
          home: DashboardShell(
            accent: Colors.red,
            appTitle: 'PowerFit',
            roleTag: 'Reception',
            userName: 'Sara',
            userRole: 'Front desk',
            navItems: const [DashNavItem(Icons.home_outlined, 'Home')],
            selectedIndex: 0,
            onSelect: (_) {},
            pageTitle: 'Home',
            onLogout: onLogout,
            showTopbar: false,
            body: const SizedBox(),
          ),
        );

    testWidgets('sidebar offers logout to every role that passes a handler',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var loggedOut = false;
      await tester.pumpWidget(shell(onLogout: () => loggedOut = true));

      expect(find.byIcon(Icons.logout), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Confirms before signing out.
      expect(loggedOut, isFalse);
      await tester.tap(find.widgetWithText(TextButton, 'تسجيل الخروج').last);
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    });

    testWidgets('cancelling the confirm keeps the session', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var loggedOut = false;
      await tester.pumpWidget(shell(onLogout: () => loggedOut = true));

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
      await tester.pumpAndSettle();

      expect(loggedOut, isFalse);
    });

    testWidgets('no logout control when no handler is wired', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(shell());

      expect(find.byIcon(Icons.logout), findsNothing);
    });
  });
}
