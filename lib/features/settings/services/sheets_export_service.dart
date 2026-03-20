import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../database/app_database.dart';
import '../../products/repositories/product_repository.dart';
import '../../sales/repositories/transaction_repository.dart';

class SheetsExportService {
  final AppDatabase _db;
  final ProductRepository _productRepo;
  final TransactionRepository _txnRepo;

  /// The Apps Script web app URL — user must configure this.
  final String appsScriptUrl;

  SheetsExportService({
    required AppDatabase db,
    required ProductRepository productRepo,
    required TransactionRepository txnRepo,
    required this.appsScriptUrl,
  })  : _db = db,
        _productRepo = productRepo,
        _txnRepo = txnRepo;

  /// Export all data to Google Sheet via Apps Script.
  Future<bool> exportAll() async {
    if (appsScriptUrl.isEmpty) return false;

    try {
      final products = await _productRepo.getAll();
      final transactions = await _txnRepo.getAll();
      final items = await _txnRepo.getAllItems();

      final payload = {
        'action': 'export',
        'products': products
            .map((p) => {
                  'product_id': p.id,
                  'name': p.name,
                  'suggested_price': p.suggestedPrice,
                  'cost_price': p.costPrice,
                  'stock_qty': p.stockQty,
                  'active': p.active,
                })
            .toList(),
        'transactions': transactions
            .map((t) => {
                  'transaction_id': t.id,
                  'date_time': t.dateTime_.toIso8601String(),
                  'total_price': t.totalPrice,
                  'notes': t.notes,
                })
            .toList(),
        'transaction_items': items
            .map((i) => {
                  'item_id': i.id,
                  'transaction_id': i.transactionId,
                  'product_id': i.productId,
                  'product_name': i.productName,
                  'quantity': i.quantity,
                  'unit_price': i.unitPrice,
                  'subtotal': i.subtotal,
                })
            .toList(),
      };

      final response = await http.post(
        Uri.parse(appsScriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        await _db.setMetadata(
          MetaKeys.lastExport,
          DateTime.now().toIso8601String(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Import products from Google Sheet via Apps Script.
  Future<int> importProducts() async {
    if (appsScriptUrl.isEmpty) return 0;

    try {
      final response = await http.post(
        Uri.parse(appsScriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'import'}),
      );

      if (response.statusCode != 200) return 0;

      final data = jsonDecode(response.body);
      final products = data['products'] as List<dynamic>? ?? [];

      int count = 0;
      final now = DateTime.now();

      for (final p in products) {
        await _productRepo.upsert(
          ProductsCompanion(
            id: Value(p['product_id'] as String),
            name: Value(p['name'] as String),
            suggestedPrice: Value(p['suggested_price'] as int),
            costPrice: Value((p['cost_price'] as int?) ?? 0),
            stockQty: Value((p['stock_qty'] as int?) ?? 0),
            active: Value((p['active'] as int?) ?? 1),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        count++;
      }

      await _db.setMetadata(
        MetaKeys.lastImport,
        DateTime.now().toIso8601String(),
      );

      return count;
    } catch (_) {
      return 0;
    }
  }
}
