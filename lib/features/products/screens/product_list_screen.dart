import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/product_providers.dart';
import '../../../shared/widgets/search_field.dart';
import '../widgets/product_tile.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final showInactive = ref.watch(showInactiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          TextButton.icon(
            icon: Icon(
              showInactive
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            label: Text(showInactive ? 'Semua' : 'Nonaktif'),
            onPressed: () {
              ref.read(showInactiveProvider.notifier).state = !showInactive;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SearchField(
            controller: _searchController,
            hintText: 'Cari produk...',
            onChanged: (value) {
              ref.read(productSearchProvider.notifier).state = value;
            },
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada produk',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => context.go('/products/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Produk'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductTile(
                      product: product,
                      onTap: () =>
                          context.go('/products/${product.id}/edit'),
                      onStockTap: () =>
                          context.go('/products/${product.id}/stock'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/products/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
