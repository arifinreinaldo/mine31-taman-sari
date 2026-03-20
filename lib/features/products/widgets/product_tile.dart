import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../database/app_database.dart';
import 'stock_badge.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onStockTap;

  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = product.active == 0;

    return ListTile(
      title: Text(
        product.name,
        style: isInactive
            ? TextStyle(
                color: Theme.of(context).colorScheme.outline,
                decoration: TextDecoration.lineThrough,
              )
            : null,
      ),
      subtitle: Text(formatIdr(product.suggestedPrice)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onStockTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StockBadge(qty: product.stockQty),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
