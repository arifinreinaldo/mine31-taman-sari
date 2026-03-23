import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/features/sales/models/cart_item.dart';
import 'package:per_taman_sari/features/sales/providers/cart_provider.dart';

CartItem _makeItem({
  String productId = 'p1',
  String productName = 'Item',
  int quantity = 1,
  int unitPrice = 10000,
  int suggestedPrice = 10000,
  int currentStock = 10,
}) {
  return CartItem(
    productId: productId,
    productName: productName,
    quantity: quantity,
    unitPrice: unitPrice,
    suggestedPrice: suggestedPrice,
    currentStock: currentStock,
  );
}

void main() {
  late ProviderContainer container;
  late CartNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(cartProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('CartNotifier', () {
    test('starts with empty cart', () {
      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('addItem adds new item', () {
      notifier.addItem(_makeItem());
      final cart = container.read(cartProvider);
      expect(cart, hasLength(1));
      expect(cart.first.productId, 'p1');
    });

    test('addItem merges quantity for same product', () {
      notifier.addItem(_makeItem(quantity: 2));
      notifier.addItem(_makeItem(quantity: 3));

      final cart = container.read(cartProvider);
      expect(cart, hasLength(1));
      expect(cart.first.quantity, 5);
    });

    test('addItem keeps separate entries for different products', () {
      notifier.addItem(_makeItem(productId: 'p1'));
      notifier.addItem(_makeItem(productId: 'p2'));

      final cart = container.read(cartProvider);
      expect(cart, hasLength(2));
    });

    test('updateItem replaces item at index', () {
      notifier.addItem(_makeItem(quantity: 1));
      notifier.updateItem(0, _makeItem(quantity: 5));

      final cart = container.read(cartProvider);
      expect(cart.first.quantity, 5);
    });

    test('removeItem removes item at index', () {
      notifier.addItem(_makeItem(productId: 'p1'));
      notifier.addItem(_makeItem(productId: 'p2'));
      notifier.removeItem(0);

      final cart = container.read(cartProvider);
      expect(cart, hasLength(1));
      expect(cart.first.productId, 'p2');
    });

    test('clear empties the cart', () {
      notifier.addItem(_makeItem(productId: 'p1'));
      notifier.addItem(_makeItem(productId: 'p2'));
      notifier.clear();

      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('totalPrice sums all items', () {
      notifier.addItem(_makeItem(
        productId: 'p1',
        quantity: 2,
        unitPrice: 10000,
      ));
      notifier.addItem(_makeItem(
        productId: 'p2',
        quantity: 3,
        unitPrice: 5000,
      ));

      expect(notifier.totalPrice, 35000); // 20000 + 15000
    });

    test('hasNegativeStockWarning is false when stock sufficient', () {
      notifier.addItem(_makeItem(quantity: 5, currentStock: 10));
      expect(notifier.hasNegativeStockWarning, isFalse);
    });

    test('hasNegativeStockWarning is true when stock insufficient', () {
      notifier.addItem(_makeItem(quantity: 15, currentStock: 10));
      expect(notifier.hasNegativeStockWarning, isTrue);
    });
  });
}
