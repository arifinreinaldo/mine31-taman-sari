import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/providers/core_providers.dart';

/// Last backup timestamp.
final lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  final db = ref.watch(databaseProvider);
  final value = await db.getMetadata(MetaKeys.lastBackup);
  if (value == null) return null;
  return DateTime.tryParse(value);
});

/// Last export timestamp.
final lastExportProvider = FutureProvider<DateTime?>((ref) async {
  final db = ref.watch(databaseProvider);
  final value = await db.getMetadata(MetaKeys.lastExport);
  if (value == null) return null;
  return DateTime.tryParse(value);
});
