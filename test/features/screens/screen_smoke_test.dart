import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/core/providers/core_providers.dart';
import 'package:per_taman_sari/database/app_database.dart';
import 'package:per_taman_sari/features/products/providers/product_providers.dart';
import 'package:per_taman_sari/features/products/screens/product_list_screen.dart';
import 'package:per_taman_sari/features/sales/providers/transaction_providers.dart';
import 'package:per_taman_sari/features/sales/screens/new_sale_screen.dart';
import 'package:per_taman_sari/features/sales/screens/sale_history_screen.dart';
import 'package:per_taman_sari/features/settings/providers/settings_providers.dart';
import 'package:per_taman_sari/features/settings/screens/settings_screen.dart';

final _now = DateTime.now();

final _sampleProduct = Product(
  id: 'p1',
  name: 'Test Bearing',
  suggestedPrice: 25000,
  costPrice: 15000,
  stockQty: 10,
  active: 1,
  createdAt: _now,
  updatedAt: _now,
);

final _sampleTransaction = Transaction(
  id: 't1',
  dateTime_: _now,
  totalPrice: 50000,
  notes: '',
  createdAt: _now,
);

/// Wrap a screen with overridden providers. A real in-memory DB is provided
/// for providers that access databaseProvider directly (e.g. NewSaleScreen's
/// productRepositoryProvider). StreamProviders are overridden to avoid Drift
/// stream cleanup timer issues in tests.
Widget _testApp(
  Widget child,
  AppDatabase db, {
  List<Product> products = const [],
  List<Transaction> transactions = const [],
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      productListProvider
          .overrideWith((ref) => Stream.value(products)),
      transactionListProvider
          .overrideWith((ref) => Stream.value(transactions)),
      lastBackupProvider.overrideWith((ref) async => null),
      lastExportProvider.overrideWith((ref) async => null),
      googleAccountProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductListScreen', () {
    testWidgets('renders app bar and FAB', (tester) async {
      await tester.pumpWidget(_testApp(const ProductListScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('Products'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty state when no products', (tester) async {
      await tester.pumpWidget(_testApp(const ProductListScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('No products yet'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(_testApp(const ProductListScreen(), db));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows product when data is provided', (tester) async {
      await tester.pumpWidget(
        _testApp(const ProductListScreen(), db, products: [_sampleProduct]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Bearing'), findsOneWidget);
    });
  });

  group('NewSaleScreen', () {
    testWidgets('renders app bar and search field', (tester) async {
      await tester.pumpWidget(_testApp(const NewSaleScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('New Sale'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows empty cart message', (tester) async {
      await tester.pumpWidget(_testApp(const NewSaleScreen(), db));
      await tester.pumpAndSettle();

      expect(
        find.text('Search and add products to start a sale'),
        findsOneWidget,
      );
    });
  });

  group('SaleHistoryScreen', () {
    testWidgets('renders app bar', (tester) async {
      await tester.pumpWidget(_testApp(const SaleHistoryScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('Sales History'), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      await tester.pumpWidget(_testApp(const SaleHistoryScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('No sales yet'), findsOneWidget);
    });

    testWidgets('shows transaction when data is provided', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SaleHistoryScreen(), db,
          transactions: [_sampleTransaction],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No sales yet'), findsNothing);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders section headers', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('Google Drive Backup'), findsOneWidget);
      expect(find.text('Google Sheets'), findsOneWidget);
    });

    testWidgets('shows backup and restore tiles', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('Backup Now'), findsOneWidget);
      expect(find.text('Restore from Backup'), findsOneWidget);
    });

    testWidgets('shows export and import tiles', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('Export to Sheet'), findsOneWidget);
      expect(find.text('Import from Sheet'), findsOneWidget);
    });

    testWidgets('shows not signed in when no account', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pumpAndSettle();

      expect(find.text('Not signed in'), findsOneWidget);
    });
  });
}
