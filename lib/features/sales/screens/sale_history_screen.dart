import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/transaction_providers.dart';
import '../widgets/transaction_tile.dart';

class SaleHistoryScreen extends ConsumerWidget {
  const SaleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: txnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sales yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              return TransactionTile(
                transaction: txn,
                onTap: () => context.go('/history/${txn.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
