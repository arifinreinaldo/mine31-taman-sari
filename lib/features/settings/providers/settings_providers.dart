import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants.dart';
import '../../../core/providers/core_providers.dart';
import '../services/google_drive_service.dart';

/// Last backup timestamp.
final lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  final db = ref.watch(databaseProvider);
  final value = await db.getMetadata(MetaKeys.lastBackup);
  if (value == null) return null;
  return DateTime.tryParse(value);
});

/// Currently signed-in Google account (null if not signed in).
final googleAccountProvider = FutureProvider<GoogleSignInAccount?>((ref) async {
  final db = ref.watch(databaseProvider);
  final service = GoogleDriveService(db);
  return service.getSignedInAccount();
});

/// Last export timestamp.
final lastExportProvider = FutureProvider<DateTime?>((ref) async {
  final db = ref.watch(databaseProvider);
  final value = await db.getMetadata(MetaKeys.lastExport);
  if (value == null) return null;
  return DateTime.tryParse(value);
});
