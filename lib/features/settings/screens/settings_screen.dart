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
          const SnackBar(content: Text('Tidak ada koneksi internet')),
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
            success ? 'Cadangan berhasil' : 'Cadangan gagal',
          ),
        ),
      );
    }
    setState(() => _backingUp = false);
  }

  Future<void> _restore() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Pulihkan Data',
      message:
          'SEMUA data di HP akan diganti dengan cadangan dari Google Drive. '
          'Tidak bisa dibatalkan.\n\n'
          'Aplikasi akan ditutup setelah selesai. Buka kembali secara manual.',
      confirmText: 'Pulihkan',
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
            title: const Text('Pemulihan Selesai'),
            content: const Text(
              'Data berhasil dipulihkan. '
              'Aplikasi akan ditutup. Silakan buka kembali.',
            ),
            actions: [
              FilledButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Tutup Aplikasi'),
              ),
            ],
          ),
        );
      case 'no_backup':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada cadangan di Google Drive')),
        );
      case 'cancelled':
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemulihan gagal')),
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
                ? 'Pengiriman berhasil'
                : 'Pengiriman gagal — atur URL Apps Script',
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
                ? '$count produk berhasil diambil'
                : 'Gagal mengambil data — atur URL Apps Script',
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
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // Google Drive Backup
          const _SectionHeader(title: 'Cadangan Google Drive'),

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
                      child: const Text('Keluar'),
                    ),
                  )
                : const ListTile(
                    leading: Icon(Icons.account_circle_outlined),
                    title: Text('Belum masuk akun'),
                    subtitle:
                        Text('Otomatis masuk saat cadangkan atau pulihkan'),
                  ),
            loading: () => const ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Memeriksa akun...'),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Belum masuk akun'),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Cadangkan Sekarang'),
            subtitle: lastBackup.when(
              data: (dt) => Text(
                dt != null ? 'Terakhir: ${formatTimeAgo(dt)}' : 'Belum pernah dicadangkan',
              ),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Tidak diketahui'),
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
            title: const Text('Pulihkan dari Cadangan'),
            subtitle: const Text('Ganti data lokal dengan cadangan Drive'),
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
            title: const Text('Kirim ke Sheet'),
            subtitle: lastExport.when(
              data: (dt) => Text(
                dt != null
                    ? 'Terakhir: ${formatTimeAgo(dt)}'
                    : 'Belum pernah dikirim',
              ),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Tidak diketahui'),
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
            title: const Text('Ambil dari Sheet'),
            subtitle: const Text('Perbarui produk dari Google Sheet'),
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
