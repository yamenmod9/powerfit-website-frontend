import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_frontend/core/localization/app_strings.dart';
import 'package:gym_frontend/shared/widgets/dash_charts.dart';
import 'package:gym_frontend/shared/widgets/dashboard_shell.dart';

/// A trend series shaped like /api/reports/revenue-trend's points.
List<Map<String, dynamic>> _points(int count, {double revenue = 1000}) => [
      for (var i = 0; i < count; i++)
        {
          'date': '2026-07-${(i + 1).toString().padLeft(2, '0')}',
          'label': '${i + 1} Jul',
          'revenue': revenue * i,
          'transactions': i,
        },
    ];

List<Map<String, dynamic>> _categories(int count) => [
      for (var i = 0; i < count; i++)
        {
          'category': 'category_$i',
          'total': (count - i) * 1000.0,
          'count': count - i,
        },
    ];

Widget _host(Widget child, {required double width}) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  // S defaults to Arabic; pin English so the text assertions below are stable.
  setUp(() => S.setArabic(false));
  tearDown(() => S.setArabic(true));

  group('DashRevenueTrendChart', () {
    // A phone column and a desktop column, each minus DashBody's 24pt padding.
    for (final width in const [342.0, 1132.0]) {
      testWidgets('lays out without overflow at ${width}pt', (tester) async {
        await tester.pumpWidget(_host(
          DashRevenueTrendChart(points: _points(14)),
          width: width,
        ));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an all-zero series still renders rather than dividing by zero',
        (tester) async {
      await tester.pumpWidget(_host(
        DashRevenueTrendChart(points: _points(7, revenue: 0)),
        width: 342,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(DashRevenueTrendChart), findsOneWidget);
    });

    testWidgets('no points falls back to the empty hint', (tester) async {
      await tester.pumpWidget(_host(
        const DashRevenueTrendChart(points: []),
        width: 342,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text(S.noRevenueData), findsOneWidget);
    });
  });

  group('DashCategoryBreakdown', () {
    testWidgets('folds the tail past maxRows into one Other row',
        (tester) async {
      await tester.pumpWidget(_host(
        DashCategoryBreakdown(categories: _categories(9)),
        width: 1132,
      ));

      // 6 shown + 1 folded row = 7 bars, never 9.
      expect(find.byType(DashProgressRow), findsNWidgets(7));
      expect(find.text(S.otherCategories(3)), findsOneWidget);
    });

    testWidgets('does not fold when the list fits', (tester) async {
      await tester.pumpWidget(_host(
        DashCategoryBreakdown(categories: _categories(4)),
        width: 1132,
      ));

      expect(find.byType(DashProgressRow), findsNWidgets(4));
      expect(find.text(S.otherCategories(0)), findsNothing);
    });

    testWidgets('distinct unmapped categories keep distinct labels',
        (tester) async {
      // Regression: expenseCategoryLabel used to fold every unmapped value into
      // "Other", which rendered adjacent bars under one repeated label.
      await tester.pumpWidget(_host(
        DashCategoryBreakdown(categories: const [
          {'category': 'services', 'total': 3000.0, 'count': 3},
          {'category': 'safety', 'total': 2000.0, 'count': 2},
          {'category': 'insurance', 'total': 1000.0, 'count': 1},
        ]),
        width: 1132,
      ));

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      expect(find.text('Insurance'), findsOneWidget);
    });

    testWidgets('long category labels do not overflow a phone-width card',
        (tester) async {
      await tester.pumpWidget(_host(
        DashCategoryBreakdown(categories: const [
          {'category': 'uncategorized', 'total': 51477.0, 'count': 22},
          {'category': 'maintenance', 'total': 34674.0, 'count': 18},
        ]),
        width: 342,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no categories falls back to the empty hint', (tester) async {
      await tester.pumpWidget(_host(
        const DashCategoryBreakdown(categories: []),
        width: 342,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(DashProgressRow), findsNothing);
    });
  });
}
