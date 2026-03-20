import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (item.wouldCauseNegativeStock)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Stock: ${item.currentStock} — will go negative',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              children: [
                // Quantity
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final qty = int.tryParse(v);
                      if (qty != null && qty > 0) {
                        onUpdate(item.copyWith(quantity: qty));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Unit price
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: 'Rp ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final price = int.tryParse(v);
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
