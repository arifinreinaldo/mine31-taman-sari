import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/database/app_database.dart';
import 'package:per_taman_sari/features/products/repositories/product_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductRepository', () {
    group('insert', () {
      test('returns generated UUID', () async {
        final id = await repo.insert(
          name: 'Bearing 6205',
          suggestedPrice: 25000,
        );
        expect(id, isNotEmpty);
      });

      test('product is queryable after insert', () async {
        final id = await repo.insert(
          name: 'Bearing 6205',
          suggestedPrice: 25000,
          costPrice: 15000,
          stockQty: 10,
        );

        final product = await repo.getById(id);
        expect(product, isNotNull);
        expect(product!.name, 'Bearing 6205');
        expect(product.suggestedPrice, 25000);
        expect(product.costPrice, 15000);
        expect(product.stockQty, 10);
        expect(product.active, 1);
      });

      test('defaults costPrice and stockQty to 0', () async {
        final id = await repo.insert(
          name: 'Seal',
          suggestedPrice: 5000,
        );

        final product = await repo.getById(id);
        expect(product!.costPrice, 0);
        expect(product.stockQty, 0);
      });
    });

    group('update', () {
      test('updates name and price', () async {
        final id = await repo.insert(
          name: 'Old Name',
          suggestedPrice: 10000,
        );

        await repo.update(
          id: id,
          name: 'New Name',
          suggestedPrice: 20000,
          costPrice: 12000,
        );

        final product = await repo.getById(id);
        expect(product!.name, 'New Name');
        expect(product.suggestedPrice, 20000);
        expect(product.costPrice, 12000);
      });

      test('does not change stock on update', () async {
        final id = await repo.insert(
          name: 'Product',
          suggestedPrice: 10000,
          stockQty: 50,
        );

        await repo.update(
          id: id,
          name: 'Product Updated',
          suggestedPrice: 12000,
        );

        final product = await repo.getById(id);
        expect(product!.stockQty, 50);
      });
    });

    group('stock operations', () {
      test('setStock sets absolute quantity', () async {
        final id = await repo.insert(
          name: 'Item',
          suggestedPrice: 1000,
          stockQty: 10,
        );

        await repo.setStock(id, 25);
        final product = await repo.getById(id);
        expect(product!.stockQty, 25);
      });

      test('deductStock reduces by amount', () async {
        final id = await repo.insert(
          name: 'Item',
          suggestedPrice: 1000,
          stockQty: 10,
        );

        await repo.deductStock(id, 3);
        final product = await repo.getById(id);
        expect(product!.stockQty, 7);
      });

      test('deductStock can go negative', () async {
        final id = await repo.insert(
          name: 'Item',
          suggestedPrice: 1000,
          stockQty: 2,
        );

        await repo.deductStock(id, 5);
        final product = await repo.getById(id);
        expect(product!.stockQty, -3);
      });

      test('deductStock no-ops for missing product', () async {
        // Should not throw
        await repo.deductStock('nonexistent', 5);
      });
    });

    group('soft delete and restore', () {
      test('softDelete sets active to 0', () async {
        final id = await repo.insert(
          name: 'Item',
          suggestedPrice: 1000,
        );

        await repo.softDelete(id);
        final product = await repo.getById(id);
        expect(product!.active, 0);
      });

      test('restore sets active to 1', () async {
        final id = await repo.insert(
          name: 'Item',
          suggestedPrice: 1000,
        );

        await repo.softDelete(id);
        await repo.restore(id);
        final product = await repo.getById(id);
        expect(product!.active, 1);
      });
    });

    group('watchAll', () {
      test('emits active products ordered by name', () async {
        await repo.insert(name: 'Zebra', suggestedPrice: 1000);
        await repo.insert(name: 'Alpha', suggestedPrice: 2000);

        final products = await repo.watchAll().first;
        expect(products, hasLength(2));
        expect(products[0].name, 'Alpha');
        expect(products[1].name, 'Zebra');
      });

      test('excludes inactive by default', () async {
        final id = await repo.insert(name: 'Item', suggestedPrice: 1000);
        await repo.softDelete(id);

        final products = await repo.watchAll().first;
        expect(products, isEmpty);
      });

      test('includes inactive when flag is set', () async {
        final id = await repo.insert(name: 'Item', suggestedPrice: 1000);
        await repo.softDelete(id);

        final products =
            await repo.watchAll(includeInactive: true).first;
        expect(products, hasLength(1));
      });
    });

    group('watchSearch', () {
      test('filters by name substring', () async {
        await repo.insert(name: 'Bearing 6205', suggestedPrice: 25000);
        await repo.insert(name: 'Seal Kit', suggestedPrice: 15000);
        await repo.insert(name: 'Bearing 6305', suggestedPrice: 30000);

        final results = await repo.watchSearch('Bearing').first;
        expect(results, hasLength(2));
      });

      test('case insensitive search', () async {
        await repo.insert(name: 'Bearing 6205', suggestedPrice: 25000);

        final results = await repo.watchSearch('bearing').first;
        expect(results, hasLength(1));
      });

      test('returns empty for no match', () async {
        await repo.insert(name: 'Bearing', suggestedPrice: 25000);

        final results = await repo.watchSearch('xyz').first;
        expect(results, isEmpty);
      });
    });

    group('getAll', () {
      test('returns all products including inactive', () async {
        await repo.insert(name: 'Active', suggestedPrice: 1000);
        final id = await repo.insert(name: 'Inactive', suggestedPrice: 2000);
        await repo.softDelete(id);

        final all = await repo.getAll();
        expect(all, hasLength(2));
      });
    });

    group('upsert', () {
      test('inserts new product', () async {
        final now = DateTime.now();
        await repo.upsert(
          ProductsCompanion(
            id: const Value('u1'),
            name: const Value('Upserted'),
            suggestedPrice: const Value(5000),
            costPrice: const Value(3000),
            stockQty: const Value(10),
            active: const Value(1),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final product = await repo.getById('u1');
        expect(product, isNotNull);
        expect(product!.name, 'Upserted');
      });

      test('updates existing product on conflict', () async {
        final now = DateTime.now();
        await repo.insert(name: 'Original', suggestedPrice: 1000);
        final all = await repo.getAll();
        final id = all.first.id;

        await repo.upsert(
          ProductsCompanion(
            id: Value(id),
            name: const Value('Updated Via Upsert'),
            suggestedPrice: const Value(9999),
            costPrice: const Value(0),
            stockQty: const Value(5),
            active: const Value(1),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final product = await repo.getById(id);
        expect(product!.name, 'Updated Via Upsert');
        expect(product.suggestedPrice, 9999);

        // Should still be only 1 product
        final count = await repo.getAll();
        expect(count, hasLength(1));
      });
    });
  });
}
