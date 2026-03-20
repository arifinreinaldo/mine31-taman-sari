import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../database/app_database.dart';
import '../providers/product_providers.dart';

class StockAdjustScreen extends ConsumerStatefulWidget {
  final String productId;

  const StockAdjustScreen({super.key, required this.productId});

  @override
  ConsumerState<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends ConsumerState<StockAdjustScreen> {
  final _stockController = TextEditingController();
  Product? _product;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getById(widget.productId);
    if (product != null && mounted) {
      setState(() {
        _product = product;
        _stockController.text = product.stockQty.toString();
      });
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newQty = int.tryParse(_stockController.text.trim());
    if (newQty == null) return;

    setState(() => _loading = true);
    await ref.read(productRepositoryProvider).setStock(widget.productId, newQty);
    if (mounted) context.pop();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adjust Stock')),
      body: _product == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _product!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Current stock: ${_product!.stockQty}'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'New Stock Quantity',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
