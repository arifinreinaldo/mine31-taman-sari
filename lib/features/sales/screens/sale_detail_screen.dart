import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../database/app_database.dart';
import '../providers/transaction_providers.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const SaleDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  Transaction? _transaction;
  List<TransactionItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(transactionRepositoryProvider);
    final txn = await repo.getById(widget.transactionId);
    final items = await repo.getItems(widget.transactionId);
    if (mounted) {
      setState(() {
        _transaction = txn;
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
              ? const Center(child: Text('Transaction not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDateTime(_transaction!.dateTime_),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIdr(_transaction!.totalPrice),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_transaction!.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _transaction!.notes,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._items.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.quantity} x ${formatIdr(item.unitPrice)}',
                          ),
                          trailing: Text(
                            formatIdr(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
