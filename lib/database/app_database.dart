import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/products_table.dart';
import 'tables/transactions_table.dart';
import 'tables/transaction_items_table.dart';
import 'tables/sync_metadata_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Products, Transactions, TransactionItems, SyncMetadata],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // --- SyncMetadata helpers ---

  Future<String?> getMetadata(String key) async {
    final row = await (select(syncMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMetadata(String key, String value) async {
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  /// Returns the path to the database file on disk.
  static Future<String> get databasePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'taman_sari.db');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbPath = await AppDatabase.databasePath;
    final file = File(dbPath);
    return NativeDatabase.createInBackground(file);
  });
}
