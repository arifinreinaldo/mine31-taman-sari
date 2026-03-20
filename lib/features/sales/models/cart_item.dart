class CartItem {
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int suggestedPrice;
  final int currentStock;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.suggestedPrice,
    required this.currentStock,
  });

  int get subtotal => quantity * unitPrice;

  CartItem copyWith({
    int? quantity,
    int? unitPrice,
  }) {
    return CartItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      suggestedPrice: suggestedPrice,
      currentStock: currentStock,
    );
  }

  /// True if selling this quantity would cause negative stock.
  bool get wouldCauseNegativeStock => quantity > currentStock;
}
