import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/search_field.dart';
import '../../products/providers/product_providers.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/transaction_providers.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addProductToCart(Product product) {
    final item = CartItem(
      productId: product.id,
      productName: product.name,
      quantity: 1,
      unitPrice: product.suggestedPrice,
      suggestedPrice: product.suggestedPrice,
      currentStock: product.stockQty,
    );
    ref.read(cartProvider.notifier).addItem(item);

    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _completeSale() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    // Warn about negative stock
    final hasNegative = cart.any((i) => i.wouldCauseNegativeStock);
    if (hasNegative) {
      final proceed = await showConfirmDialog(
        context,
        title: 'Negative Stock Warning',
        message:
            'Some items will result in negative stock. Continue anyway?',
        confirmText: 'Continue',
        isDestructive: true,
      );
      if (!proceed) return;
    }

    setState(() => _saving = true);

    await ref.read(transactionRepositoryProvider).saveSale(items: cart);
    ref.read(cartProvider.notifier).clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale completed')),
      );
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final repo = ref.watch(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear cart',
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Clear Cart',
                  message: 'Remove all items from cart?',
                  confirmText: 'Clear',
                  isDestructive: true,
                );
                if (confirmed) {
                  ref.read(cartProvider.notifier).clear();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Product search
          SearchField(
            controller: _searchController,
            hintText: 'Search product to add...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),

          // Search results
          if (_searchQuery.isNotEmpty)
            StreamBuilder<List<Product>>(
              stream: repo.watchSearch(_searchQuery),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No products found'),
                  );
                }
                return Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return ListTile(
                        dense: true,
                        title: Text(p.name),
                        subtitle: Text('Stock: ${p.stockQty}'),
                        trailing: Text('Rp ${p.suggestedPrice}'),
                        onTap: () => _addProductToCart(p),
                      );
                    },
                  ),
                );
              },
            ),

          // Cart items
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Text(
                      'Search and add products to start a sale',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(
                        item: cart[index],
                        index: index,
                        onUpdate: (updated) {
                          ref
                              .read(cartProvider.notifier)
                              .updateItem(index, updated);
                        },
                        onRemove: () {
                          ref
                              .read(cartProvider.notifier)
                              .removeItem(index);
                        },
                      );
                    },
                  ),
          ),

          // Bottom summary + confirm
          if (cart.isNotEmpty)
            CartSummary(
              items: cart,
              onConfirm: _completeSale,
              loading: _saving,
            ),
        ],
      ),
    );
  }
}
