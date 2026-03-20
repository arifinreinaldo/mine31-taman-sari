import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taman_sari_pos/database/app_database.dart';
import 'package:taman_sari_pos/features/products/repositories/product_repository.dart';
import 'package:taman_sari_pos/features/sales/models/cart_item.dart';
import 'package:taman_sari_pos/features/sales/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository productRepo;
  late TransactionRepository txnRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    productRepo = ProductRepository(db);
    txnRepo = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> insertProduct({
    required String name,
    required int price,
    int stock = 10,
  }) async {
    return productRepo.insert(
      name: name,
      suggestedPrice: price,
      stockQty: stock,
    );
  }

  group('TransactionRepository', () {
    group('saveSale', () {
      test('creates transaction with items and deducts stock', () async {
        final pid = await insertProduct(
          name: 'Bearing',
          price: 25000,
          stock: 10,
        );

        final txnId = await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Bearing',
              quantity: 3,
              unitPrice: 25000,
              suggestedPrice: 25000,
              currentStock: 10,
            ),
          ],
        );

        expect(txnId, isNotEmpty);

        // Transaction exists
        final txn = await txnRepo.getById(txnId);
        expect(txn, isNotNull);
        expect(txn!.totalPrice, 75000);

        // Items exist
        final items = await txnRepo.getItems(txnId);
        expect(items, hasLength(1));
        expect(items.first.quantity, 3);
        expect(items.first.subtotal, 75000);

        // Stock deducted
        final product = await productRepo.getById(pid);
        expect(product!.stockQty, 7);
      });

      test('handles multi-item sale', () async {
        final pid1 = await insertProduct(
          name: 'Bearing',
          price: 25000,
          stock: 10,
        );
        final pid2 = await insertProduct(
          name: 'Seal',
          price: 15000,
          stock: 20,
        );

        final txnId = await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid1,
              productName: 'Bearing',
              quantity: 2,
              unitPrice: 25000,
              suggestedPrice: 25000,
              currentStock: 10,
            ),
            CartItem(
              productId: pid2,
              productName: 'Seal',
              quantity: 5,
              unitPrice: 15000,
              suggestedPrice: 15000,
              currentStock: 20,
            ),
          ],
        );

        final txn = await txnRepo.getById(txnId);
        expect(txn!.totalPrice, 125000); // 50000 + 75000

        final items = await txnRepo.getItems(txnId);
        expect(items, hasLength(2));

        final bearing = await productRepo.getById(pid1);
        expect(bearing!.stockQty, 8);

        final seal = await productRepo.getById(pid2);
        expect(seal!.stockQty, 15);
      });

      test('stores notes', () async {
        final pid = await insertProduct(
          name: 'Item',
          price: 1000,
          stock: 5,
        );

        final txnId = await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Item',
              quantity: 1,
              unitPrice: 1000,
              suggestedPrice: 1000,
              currentStock: 5,
            ),
          ],
          notes: 'Cash payment',
        );

        final txn = await txnRepo.getById(txnId);
        expect(txn!.notes, 'Cash payment');
      });

      test('allows negative stock (no constraint)', () async {
        final pid = await insertProduct(
          name: 'Item',
          price: 1000,
          stock: 1,
        );

        await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Item',
              quantity: 5,
              unitPrice: 1000,
              suggestedPrice: 1000,
              currentStock: 1,
            ),
          ],
        );

        final product = await productRepo.getById(pid);
        expect(product!.stockQty, -4);
      });

      test('is atomic — transaction stored with items', () async {
        final pid = await insertProduct(
          name: 'Item',
          price: 10000,
          stock: 100,
        );

        await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Item',
              quantity: 2,
              unitPrice: 10000,
              suggestedPrice: 10000,
              currentStock: 100,
            ),
          ],
        );

        // Both transaction and items should exist
        final txns = await txnRepo.getAll();
        expect(txns, hasLength(1));

        final allItems = await txnRepo.getAllItems();
        expect(allItems, hasLength(1));
      });
    });

    group('watchAll', () {
      test('returns multiple transactions', () async {
        final pid = await insertProduct(
          name: 'Item',
          price: 1000,
          stock: 100,
        );

        await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Item',
              quantity: 1,
              unitPrice: 1000,
              suggestedPrice: 1000,
              currentStock: 100,
            ),
          ],
        );

        await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Item',
              quantity: 2,
              unitPrice: 1000,
              suggestedPrice: 1000,
              currentStock: 99,
            ),
          ],
        );

        final txns = await txnRepo.watchAll().first;
        expect(txns, hasLength(2));
        // Both amounts should be present
        final totals = txns.map((t) => t.totalPrice).toSet();
        expect(totals, containsAll([1000, 2000]));
      });
    });

    group('getById', () {
      test('returns null for nonexistent id', () async {
        final txn = await txnRepo.getById('nonexistent');
        expect(txn, isNull);
      });
    });

    group('getItems', () {
      test('returns empty list for nonexistent transaction', () async {
        final items = await txnRepo.getItems('nonexistent');
        expect(items, isEmpty);
      });
    });
  });
}
