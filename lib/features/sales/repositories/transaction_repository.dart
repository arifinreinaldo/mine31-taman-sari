import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart';
import '../models/cart_item.dart';

class TransactionRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  TransactionRepository(this._db);

  /// Atomic save: insert transaction + items + deduct stock — all in one
  /// database transaction. If any step fails, everything rolls back.
  Future<String> saveSale({
    required List<CartItem> items,
    String notes = '',
  }) async {
    final txnId = _uuid.v4();
    final now = DateTime.now();
    final totalPrice = items.fold<int>(0, (sum, i) => sum + i.subtotal);

    await _db.transaction(() async {
      // 1. Insert transaction
      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: txnId,
              dateTime_: now,
              totalPrice: totalPrice,
              createdAt: now,
              notes: Value(notes),
            ),
          );

      // 2. Insert line items + deduct stock
      for (final item in items) {
        await _db.into(_db.transactionItems).insert(
              TransactionItemsCompanion.insert(
                id: _uuid.v4(),
                transactionId: txnId,
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal: item.subtotal,
              ),
            );

        // Deduct stock
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.productId)))
            .getSingle();
        await (_db.update(_db.products)
              ..where((t) => t.id.equals(item.productId)))
            .write(
          ProductsCompanion(
            stockQty: Value(product.stockQty - item.quantity),
            updatedAt: Value(now),
          ),
        );
      }
    });

    return txnId;
  }

  /// Watch all transactions, newest first.
  Stream<List<Transaction>> watchAll() {
    return (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.dateTime_)]))
        .watch();
  }

  /// Get transaction by ID.
  Future<Transaction?> getById(String id) {
    return (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get line items for a transaction.
  Future<List<TransactionItem>> getItems(String transactionId) {
    return (_db.select(_db.transactionItems)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
  }

  /// Get all transactions (for export).
  Future<List<Transaction>> getAll() {
    return (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.dateTime_)]))
        .get();
  }

  /// Get all transaction items (for export).
  Future<List<TransactionItem>> getAllItems() {
    return _db.select(_db.transactionItems).get();
  }
}
