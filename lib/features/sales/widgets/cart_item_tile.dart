import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters.dart';
import '../models/cart_item.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final int index;
  final ValueChanged<CartItem> onUpdate;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  String _formatPrice(int value) {
    return NumberFormat('#,###', 'id_ID')
        .format(value)
        .replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ),
            if (item.wouldCauseNegativeStock)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Stok: ${item.currentStock} — akan minus',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              children: [
                // Quantity with +/- buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: item.quantity > 1
                          ? () => onUpdate(
                              item.copyWith(quantity: item.quantity - 1))
                          : null,
                      iconSize: 22,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => onUpdate(
                          item.copyWith(quantity: item.quantity + 1)),
                      iconSize: 22,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Unit price
                Expanded(
                  child: TextFormField(
                    initialValue: _formatPrice(item.unitPrice),
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ThousandSeparatorFormatter(),
                    ],
                    onChanged: (v) {
                      final price = parseIdr(v);
                      if (price != null && price >= 0) {
                        onUpdate(item.copyWith(unitPrice: price));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Subtotal
                Text(
                  formatIdr(item.subtotal),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
