import 'package:flutter/material.dart';

class StockBadge extends StatelessWidget {
  final int qty;

  const StockBadge({super.key, required this.qty});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (qty <= 0) {
      color = Theme.of(context).colorScheme.error;
    } else if (qty <= 5) {
      color = Colors.orange;
    } else {
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$qty',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
