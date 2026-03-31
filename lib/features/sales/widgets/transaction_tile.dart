import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../database/app_database.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  bool get _isCancelled => transaction.cancelledAt != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        formatIdr(transaction.totalPrice),
        style: _isCancelled
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.outline,
              )
            : null,
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              formatDateTime(transaction.dateTime_),
              style: _isCancelled
                  ? TextStyle(color: theme.colorScheme.outline)
                  : null,
            ),
          ),
          if (_isCancelled) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DIBATALKAN',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
