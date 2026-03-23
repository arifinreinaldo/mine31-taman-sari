import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatters.dart';
import '../../../core/providers/core_providers.dart';
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
  bool _exporting = false;
  bool _importing = false;

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    final db = ref.read(databaseProvider);
    final service = GoogleDriveService(db);
    final success = await service.backupDatabase();

    ref.invalidate(lastBackupProvider);

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

  Future<void> _export() async {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Google Drive Backup
          const _SectionHeader(title: 'Google Drive Backup'),
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
