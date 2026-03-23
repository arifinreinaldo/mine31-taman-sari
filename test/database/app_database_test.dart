import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/database/app_database.dart';

AppDatabase _createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncMetadata helpers', () {
    test('getMetadata returns null for missing key', () async {
      final value = await db.getMetadata('nonexistent');
      expect(value, isNull);
    });

    test('setMetadata and getMetadata roundtrip', () async {
      await db.setMetadata('test_key', 'test_value');
      final value = await db.getMetadata('test_key');
      expect(value, 'test_value');
    });

    test('setMetadata overwrites existing value', () async {
      await db.setMetadata('key', 'first');
      await db.setMetadata('key', 'second');
      final value = await db.getMetadata('key');
      expect(value, 'second');
    });
  });

  group('Products table', () {
    test('insert and select product', () async {
      final now = DateTime.now();
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              id: 'p1',
              name: 'Test Product',
              suggestedPrice: 10000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final products = await db.select(db.products).get();
      expect(products, hasLength(1));
      expect(products.first.name, 'Test Product');
      expect(products.first.suggestedPrice, 10000);
      expect(products.first.active, 1);
      expect(products.first.stockQty, 0);
      expect(products.first.costPrice, 0);
    });

    test('default values are applied', () async {
      final now = DateTime.now();
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              id: 'p1',
              name: 'Defaults',
              suggestedPrice: 5000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final product = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();

      expect(product.costPrice, 0);
      expect(product.stockQty, 0);
      expect(product.active, 1);
    });
  });

  group('Transactions table', () {
    test('insert transaction and items', () async {
      final now = DateTime.now();
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              id: 't1',
              dateTime_: now,
              totalPrice: 50000,
              createdAt: now,
            ),
          );

      await db.into(db.transactionItems).insert(
            TransactionItemsCompanion.insert(
              id: 'ti1',
              transactionId: 't1',
              productId: 'p1',
              productName: 'Widget A',
              quantity: 2,
              unitPrice: 25000,
              subtotal: 50000,
            ),
          );

      final txns = await db.select(db.transactions).get();
      expect(txns, hasLength(1));
      expect(txns.first.totalPrice, 50000);

      final items = await (db.select(db.transactionItems)
            ..where((t) => t.transactionId.equals('t1')))
          .get();
      expect(items, hasLength(1));
      expect(items.first.productName, 'Widget A');
      expect(items.first.quantity, 2);
    });
  });

  group('Database transactions', () {
    test('rollback on failure inside transaction', () async {
      final now = DateTime.now();

      // Insert a product first
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              id: 'p1',
              name: 'Product',
              suggestedPrice: 10000,
              stockQty: const Value(10),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Attempt a transaction that will fail
      try {
        await db.transaction(() async {
          await db.into(db.transactions).insert(
                TransactionsCompanion.insert(
                  id: 'txn1',
                  dateTime_: now,
                  totalPrice: 10000,
                  createdAt: now,
                ),
              );
          // Force a failure by inserting duplicate PK
          await db.into(db.transactions).insert(
                TransactionsCompanion.insert(
                  id: 'txn1', // duplicate
                  dateTime_: now,
                  totalPrice: 20000,
                  createdAt: now,
                ),
              );
        });
      } catch (_) {
        // Expected
      }

      // Transaction should have been rolled back
      final txns = await db.select(db.transactions).get();
      expect(txns, isEmpty);
    });
  });
}
