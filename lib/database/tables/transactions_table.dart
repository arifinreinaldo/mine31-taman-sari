import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get dateTime_ => dateTime().named('date_time')();
  IntColumn get totalPrice => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
