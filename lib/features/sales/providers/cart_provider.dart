import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';

/// In-memory cart state.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    // If product already in cart, increase quantity
    final idx = state.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      final existing = state[idx];
      final updated = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
      state = [...state]
        ..[idx] = updated;
    } else {
      state = [...state, item];
    }
  }

  void updateItem(int index, CartItem item) {
    state = [...state]
      ..[index] = item;
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
  }

  void clear() {
    state = [];
  }

  int get totalPrice => state.fold<int>(0, (sum, i) => sum + i.subtotal);

  bool get hasNegativeStockWarning =>
      state.any((i) => i.wouldCauseNegativeStock);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
