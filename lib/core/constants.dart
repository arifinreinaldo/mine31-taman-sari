/// Metadata keys stored in sync_metadata table.
abstract class MetaKeys {
  static const pinHash = 'pin_hash';
  static const lastBackup = 'last_backup';
  static const lastExport = 'last_export';
  static const lastImport = 'last_import';
}

/// Duration thresholds.
abstract class AppDurations {
  static const autoBackupInterval = Duration(hours: 24);
}
