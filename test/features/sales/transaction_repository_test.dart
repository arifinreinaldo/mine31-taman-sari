import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/database/app_database.dart';
import 'package:per_taman_sari/features/products/repositories/product_repository.dart';
import 'package:per_taman_sari/features/sales/models/cart_item.dart';
import 'package:per_taman_sari/features/sales/repositories/transaction_repository.dart';

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

    group('cancelSale', () {
      test('reverses stock and sets cancelledAt/cancelReason', () async {
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

        // Stock should be 7 after sale
        var product = await productRepo.getById(pid);
        expect(product!.stockQty, 7);

        await txnRepo.cancelSale(
          transactionId: txnId,
          reason: 'Wrong price',
        );

        // Stock should be restored to 10
        product = await productRepo.getById(pid);
        expect(product!.stockQty, 10);

        // Transaction should be marked cancelled
        final txn = await txnRepo.getById(txnId);
        expect(txn!.cancelledAt, isNotNull);
        expect(txn.cancelReason, 'Wrong price');
      });

      test('reverses stock for multi-item sale', () async {
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

        await txnRepo.cancelSale(
          transactionId: txnId,
          reason: 'Customer cancelled',
        );

        final bearing = await productRepo.getById(pid1);
        expect(bearing!.stockQty, 10);

        final seal = await productRepo.getById(pid2);
        expect(seal!.stockQty, 20);
      });

      test('throws when cancelling already-cancelled transaction', () async {
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
        );

        await txnRepo.cancelSale(
          transactionId: txnId,
          reason: 'First cancel',
        );

        expect(
          () => txnRepo.cancelSale(
            transactionId: txnId,
            reason: 'Second cancel',
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('loadItemsAsCart', () {
      test('returns cart items with current product data', () async {
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
              unitPrice: 20000,
              suggestedPrice: 25000,
              currentStock: 10,
            ),
          ],
        );

        // Cancel first to restore stock (mimics edit flow)
        await txnRepo.cancelSale(
          transactionId: txnId,
          reason: 'Edit',
        );

        final cartItems = await txnRepo.loadItemsAsCart(txnId);
        expect(cartItems, hasLength(1));
        expect(cartItems.first.productId, pid);
        expect(cartItems.first.productName, 'Bearing');
        expect(cartItems.first.quantity, 3);
        expect(cartItems.first.unitPrice, 20000);
        // suggestedPrice comes from current product
        expect(cartItems.first.suggestedPrice, 25000);
        // Stock restored after cancel
        expect(cartItems.first.currentStock, 10);
      });

      test('handles deleted product gracefully', () async {
        final pid = await insertProduct(
          name: 'Obsolete',
          price: 5000,
          stock: 10,
        );

        final txnId = await txnRepo.saveSale(
          items: [
            CartItem(
              productId: pid,
              productName: 'Obsolete',
              quantity: 2,
              unitPrice: 5000,
              suggestedPrice: 5000,
              currentStock: 10,
            ),
          ],
        );

        // Soft-delete the product
        await productRepo.softDelete(pid);

        // loadItemsAsCart should still work (product still in DB, just inactive)
        final cartItems = await txnRepo.loadItemsAsCart(txnId);
        expect(cartItems, hasLength(1));
        expect(cartItems.first.productName, 'Obsolete');
      });
    });
  });
}
