import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taman_sari_pos/core/providers/core_providers.dart';
import 'package:taman_sari_pos/database/app_database.dart';
import 'package:taman_sari_pos/features/products/screens/product_list_screen.dart';
import 'package:taman_sari_pos/features/sales/screens/new_sale_screen.dart';
import 'package:taman_sari_pos/features/sales/screens/sale_history_screen.dart';
import 'package:taman_sari_pos/features/settings/screens/settings_screen.dart';

/// Wraps a widget with MaterialApp and ProviderScope using an in-memory DB.
Widget _testApp(Widget child, AppDatabase db) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(home: child),
  );
}

/// Dispose widget tree and flush Drift's cleanup timers.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
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
      await tester.pump();
      await tester.pump();

      expect(find.text('Products'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows empty state when no products', (tester) async {
      await tester.pumpWidget(_testApp(const ProductListScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('No products yet'), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(_testApp(const ProductListScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows product after inserting one', (tester) async {
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              id: 'p1',
              name: 'Test Bearing',
              suggestedPrice: 25000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(_testApp(const ProductListScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Bearing'), findsOneWidget);

      await _disposeTree(tester);
    });
  });

  group('NewSaleScreen', () {
    testWidgets('renders app bar and search field', (tester) async {
      await tester.pumpWidget(_testApp(const NewSaleScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('New Sale'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows empty cart message', (tester) async {
      await tester.pumpWidget(_testApp(const NewSaleScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Search and add products to start a sale'),
        findsOneWidget,
      );

      await _disposeTree(tester);
    });
  });

  group('SaleHistoryScreen', () {
    testWidgets('renders app bar', (tester) async {
      await tester.pumpWidget(_testApp(const SaleHistoryScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sales History'), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows empty state when no transactions', (tester) async {
      await tester.pumpWidget(_testApp(const SaleHistoryScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('No sales yet'), findsOneWidget);

      await _disposeTree(tester);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders section headers', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('Google Drive Backup'), findsOneWidget);
      expect(find.text('Google Sheets'), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows backup and restore tiles', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('Backup Now'), findsOneWidget);
      expect(find.text('Restore from Backup'), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('shows export and import tiles', (tester) async {
      await tester.pumpWidget(_testApp(const SettingsScreen(), db));
      await tester.pump();
      await tester.pump();

      expect(find.text('Export to Sheet'), findsOneWidget);
      expect(find.text('Import from Sheet'), findsOneWidget);

      await _disposeTree(tester);
    });
  });
}
