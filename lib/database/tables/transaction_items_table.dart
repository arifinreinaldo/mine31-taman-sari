import 'package:drift/drift.dart';

import 'transactions_table.dart';
import 'products_table.dart';

class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id)();
  TextColumn get productId =>
      text().references(Products, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get subtotal => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
