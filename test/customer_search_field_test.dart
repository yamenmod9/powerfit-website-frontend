import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_frontend/core/api/api_endpoints.dart';
import 'package:gym_frontend/core/api/api_service.dart';
import 'package:gym_frontend/features/reception/providers/reception_provider.dart';
import 'package:gym_frontend/features/reception/widgets/customer_search_field.dart';
import 'package:gym_frontend/shared/models/customer_model.dart';
import 'package:provider/provider.dart';

/// Stands in for the backend: records what was asked and replays canned rows.
class _FakeApiService extends ApiService {
  final List<String> requestedPaths = [];
  final Map<String, dynamic> queries = {};

  /// Rows returned by /api/customers/search.
  List<Map<String, dynamic>> searchResults = [];

  /// Row returned by /api/customers/{id}, if any.
  Map<String, dynamic>? customerById;

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    requestedPaths.add(path);
    if (queryParameters != null) queries.addAll(queryParameters);

    if (path == ApiEndpoints.customerSearch) {
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'data': {'items': searchResults, 'total': searchResults.length},
        },
      );
    }

    if (customerById != null && path.startsWith('/api/customers/')) {
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {'success': true, 'data': customerById},
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(requestOptions: RequestOptions(path: path), statusCode: 404),
    );
  }
}

Map<String, dynamic> _customer(int id, String name, {String? phone, String? email}) => {
      'id': id,
      'full_name': name,
      'phone': phone,
      'email': email,
    };

void main() {
  late _FakeApiService api;
  CustomerModel? selected;

  Future<void> pumpField(WidgetTester tester) async {
    selected = null;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReceptionProvider(api, 1)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CustomerSearchField(
                selected: selected,
                onSelected: (customer) => setState(() => selected = customer),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() => api = _FakeApiService());

  testWidgets('typing a partial name drops down the matches', (tester) async {
    api.searchResults = [
      _customer(7, 'Sara Ahmed', phone: '0500000001'),
      _customer(9, 'Sarah Nour', phone: '0500000002'),
    ];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), 'sar');
    await tester.pump(const Duration(milliseconds: 400)); // debounce
    await tester.pumpAndSettle();

    expect(find.text('Sara Ahmed'), findsOneWidget);
    expect(find.text('Sarah Nour'), findsOneWidget);
    expect(api.queries['q'], 'sar');
  });

  testWidgets('searching by phone works — no ID needed', (tester) async {
    api.searchResults = [_customer(7, 'Sara Ahmed', phone: '0500000001')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), '05000');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Sara Ahmed'), findsOneWidget);
  });

  testWidgets('phone-shaped digits do not fire a doomed ID lookup',
      (tester) async {
    api.searchResults = [_customer(7, 'Sara Ahmed', phone: '0500000001')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), '0500000001');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      api.requestedPaths.where((p) => p != ApiEndpoints.customerSearch),
      isEmpty,
      reason: 'a zero-led, 10-digit query is a phone, not a row ID',
    );
    expect(find.text('Sara Ahmed'), findsOneWidget);
  });

  testWidgets('picking a match selects that member', (tester) async {
    api.searchResults = [_customer(7, 'Sara Ahmed', phone: '0500000001')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), 'sara');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sara Ahmed'));
    await tester.pumpAndSettle();

    expect(selected?.id, 7);
    expect(selected?.fullName, 'Sara Ahmed');
  });

  testWidgets('a numeric query also resolves the customer ID directly',
      (tester) async {
    // /search does not match the primary key, so the ID endpoint covers it.
    api.searchResults = [];
    api.customerById = _customer(42, 'Omar Khaled', phone: '0555555555');

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), '42');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Omar Khaled'), findsOneWidget);
    expect(api.requestedPaths, contains('/api/customers/42'));
  });

  testWidgets('an exact ID match is listed above fuzzy matches', (tester) async {
    api.customerById = _customer(42, 'Omar Khaled');
    api.searchResults = [_customer(7, 'Member 42 Fan')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), '42');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final omar = tester.getRect(find.text('Omar Khaled'));
    final other = tester.getRect(find.text('Member 42 Fan'));
    expect(omar.top, lessThan(other.top));
  });

  testWidgets('no duplicate row when both lookups return the same member',
      (tester) async {
    api.customerById = _customer(42, 'Omar Khaled');
    api.searchResults = [_customer(42, 'Omar Khaled')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), '42');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Omar Khaled'), findsOneWidget);
  });

  testWidgets('editing after a pick clears the stale selection', (tester) async {
    api.searchResults = [_customer(7, 'Sara Ahmed')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), 'sara');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sara Ahmed'));
    await tester.pumpAndSettle();
    expect(selected, isNotNull);

    // Reopen the field and type again.
    await tester.tap(find.byType(TextButton)); // "change"
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'someone else');
    await tester.pump();

    expect(selected, isNull);
  });

  testWidgets('one debounced request per pause, not one per keystroke',
      (tester) async {
    api.searchResults = [_customer(7, 'Sara Ahmed')];

    await pumpField(tester);
    await tester.enterText(find.byType(TextFormField), 's');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextFormField), 'sa');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextFormField), 'sar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final searches =
        api.requestedPaths.where((p) => p == ApiEndpoints.customerSearch).length;
    expect(searches, 1);
    expect(api.queries['q'], 'sar');
  });
}
