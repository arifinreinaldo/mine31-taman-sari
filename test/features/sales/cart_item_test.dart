import 'package:flutter_test/flutter_test.dart';
import 'package:taman_sari_pos/features/sales/models/cart_item.dart';

void main() {
  group('CartItem', () {
    test('subtotal is quantity * unitPrice', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 3,
        unitPrice: 10000,
        suggestedPrice: 10000,
        currentStock: 10,
      );
      expect(item.subtotal, 30000);
    });

    test('copyWith overrides quantity', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 1,
        unitPrice: 5000,
        suggestedPrice: 5000,
        currentStock: 10,
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.unitPrice, 5000);
      expect(updated.productId, 'p1');
    });

    test('copyWith overrides unitPrice', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 2,
        unitPrice: 5000,
        suggestedPrice: 5000,
        currentStock: 10,
      );
      final updated = item.copyWith(unitPrice: 7000);
      expect(updated.unitPrice, 7000);
      expect(updated.quantity, 2);
      expect(updated.subtotal, 14000);
    });

    test('wouldCauseNegativeStock when quantity > currentStock', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 11,
        unitPrice: 1000,
        suggestedPrice: 1000,
        currentStock: 10,
      );
      expect(item.wouldCauseNegativeStock, isTrue);
    });

    test('wouldCauseNegativeStock false when quantity <= currentStock', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 10,
        unitPrice: 1000,
        suggestedPrice: 1000,
        currentStock: 10,
      );
      expect(item.wouldCauseNegativeStock, isFalse);
    });

    test('wouldCauseNegativeStock true when currentStock is 0', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 1,
        unitPrice: 1000,
        suggestedPrice: 1000,
        currentStock: 0,
      );
      expect(item.wouldCauseNegativeStock, isTrue);
    });
  });
}
