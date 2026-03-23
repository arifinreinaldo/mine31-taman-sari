import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'database/app_database.dart';
import 'features/settings/services/google_drive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();

  _tryAutoBackup(db);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const TamanSariApp(),
    ),
  );
}

/// Silently trigger a backup if >24h since last and user is already signed in.
/// Runs async without blocking app startup.
void _tryAutoBackup(AppDatabase db) async {
  try {
    final service = GoogleDriveService(db);
    if (!await service.shouldAutoBackup()) return;

    // Only proceed if user is already signed in — never prompt on cold start
    final account = await service.getSignedInAccount();
    if (account == null) return;

    await service.backupDatabase();
  } catch (_) {
    // Silently ignore — auto-backup is best-effort
  }
}
