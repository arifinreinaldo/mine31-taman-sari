import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../database/app_database.dart';
import '../providers/cart_provider.dart';
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

  bool get _isCancelled => _transaction?.cancelledAt != null;

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

  Future<void> _handleEdit() async {
    final reason = await _showCancelReasonDialog();
    if (reason == null) return; // user dismissed

    final repo = ref.read(transactionRepositoryProvider);

    // 1. Cancel the original transaction
    await repo.cancelSale(
      transactionId: widget.transactionId,
      reason: reason,
    );

    // 2. Load items into cart
    final cartItems = await repo.loadItemsAsCart(widget.transactionId);
    ref.read(cartProvider.notifier).loadItems(cartItems);

    if (!mounted) return;

    // 3. Navigate to new sale screen
    context.go('/sale');
  }

  Future<String?> _showCancelReasonDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel & Edit Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will cancel the original sale and open a new one with the same items. Please provide a reason.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Cancel reason',
                hintText: 'e.g. Wrong price, item correction',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop(reason);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Cancel & Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Detail'),
        actions: [
          if (!_loading && _transaction != null && !_isCancelled)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit sale',
              onPressed: _handleEdit,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
              ? const Center(child: Text('Transaction not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cancelled banner
                    if (_isCancelled) ...[
                      Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CANCELLED',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_transaction!.cancelReason != null &&
                                        _transaction!
                                            .cancelReason!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _transaction!.cancelReason!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      formatDateTime(
                                          _transaction!.cancelledAt!),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Transaction header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDateTime(_transaction!.dateTime_),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIdr(_transaction!.totalPrice),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: _isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (_transaction!.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _transaction!.notes,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Items',
                      style: theme.textTheme.titleMedium,
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
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
