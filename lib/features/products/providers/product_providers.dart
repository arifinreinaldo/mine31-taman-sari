import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../database/app_database.dart';
import '../repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(databaseProvider));
});

/// Whether to show inactive products in the list.
final showInactiveProvider = StateProvider<bool>((ref) => false);

/// Current search query.
final productSearchProvider = StateProvider<String>((ref) => '');

/// Stream of products based on search and inactive toggle.
final productListProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final search = ref.watch(productSearchProvider);
  final showInactive = ref.watch(showInactiveProvider);

  if (search.isEmpty) {
    return repo.watchAll(includeInactive: showInactive);
  }
  return repo.watchSearch(search, includeInactive: showInactive);
});
