/// Metadata keys stored in sync_metadata table.
abstract class MetaKeys {
  static const lastBackup = 'last_backup';
  static const lastExport = 'last_export';
  static const lastImport = 'last_import';
}

/// File names used across the app.
abstract class AppFiles {
  static const databaseName = 'operation.db';
  static const backupFolder = 'com.sales.back';
  static const maxBackupCount = 5;
}

/// Duration thresholds.
abstract class AppDurations {
  static const autoBackupInterval = Duration(hours: 24);
}
