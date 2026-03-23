import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatters.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../products/repositories/product_repository.dart';
import '../../sales/repositories/transaction_repository.dart';
import '../providers/settings_providers.dart';
import '../services/google_drive_service.dart';
import '../services/sheets_export_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _backingUp = false;
  bool _restoring = false;
  bool _exporting = false;
  bool _importing = false;

  /// Returns true if connected, false (with snackbar) if offline.
  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _backup() async {
    if (!await _checkConnectivity()) return;
    setState(() => _backingUp = true);
    final db = ref.read(databaseProvider);
    final service = GoogleDriveService(db);
    final success = await service.backupDatabase();

    ref.invalidate(lastBackupProvider);
    ref.invalidate(googleAccountProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Backup completed' : 'Backup failed',
          ),
        ),
      );
    }
    setState(() => _backingUp = false);
  }

  Future<void> _restore() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Restore Backup',
      message:
          'This will replace ALL local data with the backup from Google Drive. '
          'This action cannot be undone.\n\n'
          'The app will close after restoring. Please reopen it manually.',
      confirmText: 'Restore',
      isDestructive: true,
    );
    if (!confirmed) return;
    if (!await _checkConnectivity()) return;

    setState(() => _restoring = true);
    final db = ref.read(databaseProvider);
    final service = GoogleDriveService(db);
    final result = await service.restoreDatabase();

    ref.invalidate(googleAccountProvider);

    if (!mounted) return;

    switch (result) {
      case 'success':
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore Complete'),
            content: const Text(
              'The database has been restored. '
              'The app will now close. Please reopen it.',
            ),
            actions: [
              FilledButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Close App'),
              ),
            ],
          ),
        );
      case 'no_backup':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backup found on Google Drive')),
        );
      case 'cancelled':
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed')),
        );
    }
    setState(() => _restoring = false);
  }

  Future<void> _signOut() async {
    final db = ref.read(databaseProvider);
    final service = GoogleDriveService(db);
    await service.signOut();
    ref.invalidate(googleAccountProvider);
  }

  Future<void> _export() async {
    if (!await _checkConnectivity()) return;
    setState(() => _exporting = true);

    final db = ref.read(databaseProvider);
    final service = SheetsExportService(
      db: db,
      productRepo: ProductRepository(db),
      txnRepo: TransactionRepository(db),
      appsScriptUrl: '', // TODO: configure via settings
    );

    final success = await service.exportAll();

    ref.invalidate(lastExportProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Export completed'
                : 'Export failed — configure Apps Script URL',
          ),
        ),
      );
    }
    setState(() => _exporting = false);
  }

  Future<void> _import() async {
    if (!await _checkConnectivity()) return;
    setState(() => _importing = true);

    final db = ref.read(databaseProvider);
    final service = SheetsExportService(
      db: db,
      productRepo: ProductRepository(db),
      txnRepo: TransactionRepository(db),
      appsScriptUrl: '', // TODO: configure via settings
    );

    final count = await service.importProducts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Imported $count products'
                : 'Import failed — configure Apps Script URL',
          ),
        ),
      );
    }
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final lastBackup = ref.watch(lastBackupProvider);
    final lastExport = ref.watch(lastExportProvider);
    final googleAccount = ref.watch(googleAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Google Drive Backup
          const _SectionHeader(title: 'Google Drive Backup'),

          // Signed-in account display
          googleAccount.when(
            data: (account) => account != null
                ? ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(account.displayName ?? account.email),
                    subtitle: account.displayName != null
                        ? Text(account.email)
                        : null,
                    trailing: TextButton(
                      onPressed: _signOut,
                      child: const Text('Sign Out'),
                    ),
                  )
                : const ListTile(
                    leading: Icon(Icons.account_circle_outlined),
                    title: Text('Not signed in'),
                    subtitle:
                        Text('Sign in automatically on backup or restore'),
                  ),
            loading: () => const ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Checking account...'),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Not signed in'),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Backup Now'),
            subtitle: lastBackup.when(
              data: (dt) => Text(
                dt != null ? 'Last: ${formatTimeAgo(dt)}' : 'Never backed up',
              ),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Unknown'),
            ),
            trailing: _backingUp
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _backingUp ? null : _backup,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Restore from Backup'),
            subtitle: const Text('Replace local data with Drive backup'),
            trailing: _restoring
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _restoring ? null : _restore,
          ),

          const Divider(),

          // Google Sheets
          const _SectionHeader(title: 'Google Sheets'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export to Sheet'),
            subtitle: lastExport.when(
              data: (dt) => Text(
                dt != null
                    ? 'Last: ${formatTimeAgo(dt)}'
                    : 'Never exported',
              ),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Unknown'),
            ),
            trailing: _exporting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _exporting ? null : _export,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import from Sheet'),
            subtitle: const Text('Upsert products from Google Sheet'),
            trailing: _importing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _importing ? null : _import,
          ),

        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
