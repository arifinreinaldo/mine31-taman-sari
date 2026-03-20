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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(formatIdr(transaction.totalPrice)),
      subtitle: Text(formatDateTime(transaction.dateTime_)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
