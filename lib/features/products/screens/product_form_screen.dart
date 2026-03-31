import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/product_providers.dart';
import '../../../database/app_database.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();

  bool _loading = false;
  Product? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getById(widget.productId!);
    if (product != null && mounted) {
      setState(() {
        _existing = product;
        _nameController.text = product.name;
        _priceController.text = product.suggestedPrice.toString();
        _costController.text =
            product.costPrice > 0 ? product.costPrice.toString() : '';
        _stockController.text = product.stockQty.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final repo = ref.read(productRepositoryProvider);
    final name = _nameController.text.trim();
    final price = int.parse(_priceController.text.trim());
    final cost = _costController.text.trim().isEmpty
        ? 0
        : int.parse(_costController.text.trim());

    if (widget.isEditing) {
      await repo.update(
        id: widget.productId!,
        name: name,
        suggestedPrice: price,
        costPrice: cost,
      );
    } else {
      final stock = _stockController.text.trim().isEmpty
          ? 0
          : int.parse(_stockController.text.trim());
      await repo.insert(
        name: name,
        suggestedPrice: price,
        costPrice: cost,
        stockQty: stock,
      );
    }

    if (mounted) context.pop();
    setState(() => _loading = false);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Nonaktifkan Produk',
      message:
          '"${_existing!.name}" tidak akan muncul di pencarian penjualan. Bisa diaktifkan kembali nanti.',
      confirmText: 'Nonaktifkan',
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(productRepositoryProvider).softDelete(widget.productId!);
    if (mounted) context.pop();
  }

  Future<void> _restore() async {
    await ref.read(productRepositoryProvider).restore(widget.productId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Ubah Produk' : 'Produk Baru'),
        actions: [
          if (widget.isEditing && _existing != null)
            _existing!.active == 1
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Nonaktifkan',
                    onPressed: _delete,
                  )
                : IconButton(
                    icon: const Icon(Icons.restore),
                    tooltip: 'Aktifkan Kembali',
                    onPressed: _restore,
                  ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga Jual',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Harga harus diisi';
                if (int.tryParse(v.trim()) == null) return 'Angka tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Harga Modal (opsional)',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok Awal',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Simpan' : 'Tambah Produk'),
            ),
          ],
        ),
      ),
    );
  }
}
