import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_frontend/core/localization/app_strings.dart';
import 'package:gym_frontend/core/utils/helpers.dart';
import 'package:gym_frontend/features/finance/providers/finance_provider.dart';
import 'package:gym_frontend/features/finance/screens/money_management_view.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> _expense({
  required int id,
  required String category,
  double amount = 100,
  String status = 'approved',
}) =>
    {
      'id': id,
      'title': 'Expense $id',
      'amount': amount,
      'category': category,
      'status': status,
      'branch_name': 'Dragon Club',
      'created_by_name': 'Reception One',
      'expense_date': '2026-02-14',
    };

/// Shaped like /api/reports/expenses-by-category: server-side totals, which are
/// deliberately larger than the visible page to prove the chips report the
/// aggregate rather than summing the rows on screen.
List<Map<String, dynamic>> get _categoryTotals => [
      {'category': 'equipment', 'total': 36063.0, 'count': 15},
      {'category': 'maintenance', 'total': 30397.0, 'count': 15},
    ];

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Provider<Object>.value(value: Object(), child: child),
      ),
    );

void main() {
  setUp(() => S.setArabic(false));
  tearDown(() => S.setArabic(true));

  group('money page category filter', () {
    testWidgets('a chip per category plus an all-categories chip',
        (tester) async {
      await tester.pumpWidget(_host(MoneyManagementView(
        earnings: 100000,
        expenses: [
          _expense(id: 1, category: 'equipment'),
          _expense(id: 2, category: 'maintenance'),
        ],
        categoryTotals: _categoryTotals,
        branches: const [],
        onRefresh: () async {},
      )));

      expect(find.text(S.allCategories), findsOneWidget);
      expect(find.text(S.expenseCategoryLabel('equipment')), findsWidgets);
      expect(find.text(S.expenseCategoryLabel('maintenance')), findsWidgets);
    });

    testWidgets('chips report the server aggregate, not the visible rows',
        (tester) async {
      await tester.pumpWidget(_host(MoneyManagementView(
        earnings: 100000,
        // One 100-unit row on screen, but the server says equipment is 36,063.
        expenses: [_expense(id: 1, category: 'equipment', amount: 100)],
        categoryTotals: _categoryTotals,
        branches: const [],
        onRefresh: () async {},
      )));

      // The chip must show the aggregate — summing the page would say 100.
      expect(find.text(NumberHelper.formatCurrency(36063)), findsOneWidget);
    });

    testWidgets('tapping a chip narrows the list to that category',
        (tester) async {
      await tester.pumpWidget(_host(MoneyManagementView(
        earnings: 100000,
        expenses: [
          _expense(id: 1, category: 'equipment'),
          _expense(id: 2, category: 'maintenance'),
          _expense(id: 3, category: 'maintenance'),
        ],
        categoryTotals: _categoryTotals,
        branches: const [],
        onRefresh: () async {},
      )));

      expect(find.text('Expense 1'), findsOneWidget);
      expect(find.text('Expense 2'), findsOneWidget);

      await tester.tap(find.text(S.expenseCategoryLabel('maintenance')).first);
      await tester.pumpAndSettle();

      // Equipment drops out; both maintenance rows stay.
      expect(find.text('Expense 1'), findsNothing);
      expect(find.text('Expense 2'), findsOneWidget);
      expect(find.text('Expense 3'), findsOneWidget);
    });

    testWidgets('a category with nothing on this page says so', (tester) async {
      await tester.pumpWidget(_host(MoneyManagementView(
        earnings: 100000,
        expenses: [_expense(id: 1, category: 'equipment')],
        categoryTotals: _categoryTotals,
        branches: const [],
        onRefresh: () async {},
      )));

      await tester.tap(find.text(S.expenseCategoryLabel('maintenance')).first);
      await tester.pumpAndSettle();

      expect(find.text(S.noExpensesInCategory), findsOneWidget);
    });

    testWidgets('no chips at all when the server sent no totals',
        (tester) async {
      await tester.pumpWidget(_host(MoneyManagementView(
        earnings: 100000,
        expenses: [_expense(id: 1, category: 'equipment')],
        branches: const [],
        onRefresh: () async {},
      )));

      expect(find.text(S.allCategories), findsNothing);
      expect(find.text('Expense 1'), findsOneWidget);
    });
  });

  group('ExpenseCategories', () {
    test('every category the dialog offers has a real label', () {
      for (final category in ExpenseCategories.all) {
        // The label falls back to echoing the raw value, so an unmapped
        // category is one whose label is just its own identifier.
        expect(S.expenseCategoryLabel(category), isNot(category),
            reason: '$category has no localized label');
      }
    });

    test('includes the categories seeded data actually uses', () {
      // These existed in the database while the column was free text but were
      // missing from the dialog's list.
      for (final category in ['services', 'safety', 'insurance', 'training']) {
        expect(ExpenseCategories.all, contains(category));
      }
    });

    test('matches the backend ExpenseCategory enum exactly', () {
      // The backend is the source of truth and rejects anything outside its
      // enum, so a category offered here that it does not know is a 400 waiting
      // to happen — and one it has that is missing here cannot be filed at all.
      // Mirrors app/models/expense.py::ExpenseCategory.
      const backendEnum = {
        'rent', 'salaries', 'utilities', 'equipment', 'maintenance',
        'supplies', 'marketing', 'insurance', 'training', 'services',
        'safety', 'software', 'other',
      };
      expect(ExpenseCategories.all.toSet(), backendEnum);
    });

    test('has no duplicates', () {
      expect(ExpenseCategories.all.toSet().length, ExpenseCategories.all.length);
    });
  });
}
