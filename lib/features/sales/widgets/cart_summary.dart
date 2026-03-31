import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../models/cart_item.dart';

class CartSummary extends StatelessWidget {
  final List<CartItem> items;
  final VoidCallback onConfirm;
  final bool loading;

  const CartSummary({
    super.key,
    required this.items,
    required this.onConfirm,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, i) => sum + i.subtotal);
    final itemCount = items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatIdr(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '$itemCount barang',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: items.isEmpty || loading ? null : onConfirm,
              icon: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Selesaikan'),
            ),
          ],
        ),
      ),
    );
  }
}
