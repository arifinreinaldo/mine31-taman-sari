import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../database/app_database.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

/// Stream of all transactions, newest first.
final transactionListProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});
