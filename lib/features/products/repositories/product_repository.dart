import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart';

class ProductRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ProductRepository(this._db);

  /// Watch all active products, ordered by name.
  Stream<List<Product>> watchAll({bool includeInactive = false}) {
    final query = _db.select(_db.products)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (!includeInactive) {
      query.where((t) => t.active.equals(1));
    }
    return query.watch();
  }

  /// Search products by name.
  Stream<List<Product>> watchSearch(String term,
      {bool includeInactive = false}) {
    final query = _db.select(_db.products)
      ..where((t) => t.name.like('%$term%'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (!includeInactive) {
      query.where((t) => t.active.equals(1));
    }
    return query.watch();
  }

  /// Get a single product by ID.
  Future<Product?> getById(String id) {
    return (_db.select(_db.products)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new product. Returns the generated ID.
  Future<String> insert({
    required String name,
    required int suggestedPrice,
    int costPrice = 0,
    int stockQty = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: id,
            name: name,
            suggestedPrice: suggestedPrice,
            costPrice: Value(costPrice),
            stockQty: Value(stockQty),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Update an existing product.
  Future<void> update({
    required String id,
    required String name,
    required int suggestedPrice,
    int costPrice = 0,
  }) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        name: Value(name),
        suggestedPrice: Value(suggestedPrice),
        costPrice: Value(costPrice),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Adjust stock quantity to an absolute value.
  Future<void> setStock(String id, int newQty) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        stockQty: Value(newQty),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deduct stock by a given amount (used during sale).
  Future<void> deductStock(String id, int amount) async {
    final product = await getById(id);
    if (product == null) return;
    await setStock(id, product.stockQty - amount);
  }

  /// Soft-delete: set active = 0.
  Future<void> softDelete(String id) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        active: const Value(0),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Restore a soft-deleted product.
  Future<void> restore(String id) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        active: const Value(1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Upsert a product by ID (used for sheet import).
  Future<void> upsert(ProductsCompanion companion) async {
    await _db.into(_db.products).insertOnConflictUpdate(companion);
  }

  /// Get all products (for export).
  Future<List<Product>> getAll() {
    return (_db.select(_db.products)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }
}
