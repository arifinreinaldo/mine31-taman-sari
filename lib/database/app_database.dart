import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../core/constants.dart';
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(transactions, transactions.cancelledAt);
          await migrator.addColumn(transactions, transactions.cancelReason);
        }
      },
    );
  }

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
    return p.join(dir.path, AppFiles.databaseName);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbPath = await AppDatabase.databasePath;
    final file = File(dbPath);
    return NativeDatabase.createInBackground(file);
  });
}
