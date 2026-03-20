import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get suggestedPrice => integer()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  IntColumn get active => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
