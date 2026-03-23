import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../database/app_database.dart';

class GoogleDriveService {
  final AppDatabase _db;

  GoogleDriveService(this._db);

  static final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  /// Sign in and return authenticated HTTP client.
  Future<http.Client?> _getAuthClient() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) return null;

    return _AuthClient(token);
  }

  /// Upload the database file to Google Drive.
  Future<bool> backupDatabase() async {
    final client = await _getAuthClient();
    if (client == null) return false;

    try {
      final driveApi = drive.DriveApi(client);
      final dbPath = await AppDatabase.databasePath;
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) return false;

      // Search for existing backup file
      const fileName = 'taman_sari_backup.db';
      final existing = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
      );

      final media = drive.Media(dbFile.openRead(), await dbFile.length());

      if (existing.files != null && existing.files!.isNotEmpty) {
        // Update existing file
        await driveApi.files.update(
          drive.File()..name = fileName,
          existing.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        await driveApi.files.create(
          drive.File()..name = fileName,
          uploadMedia: media,
        );
      }

      await _db.setMetadata(
        MetaKeys.lastBackup,
        DateTime.now().toIso8601String(),
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Check if auto-backup is needed (>24h since last backup).
  Future<bool> shouldAutoBackup() async {
    final lastStr = await _db.getMetadata(MetaKeys.lastBackup);
    if (lastStr == null) return true;
    final last = DateTime.tryParse(lastStr);
    if (last == null) return true;
    return DateTime.now().difference(last) > AppDurations.autoBackupInterval;
  }

  /// Download backup from Google Drive and replace local database.
  /// Returns a status string: 'success', 'no_backup', 'cancelled', or 'error'.
  Future<String> restoreDatabase() async {
    final client = await _getAuthClient();
    if (client == null) return 'cancelled';

    try {
      final driveApi = drive.DriveApi(client);

      // Search for the backup file
      const fileName = 'taman_sari_backup.db';
      final existing = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
      );

      if (existing.files == null || existing.files!.isEmpty) {
        return 'no_backup';
      }

      final fileId = existing.files!.first.id!;

      // Download to a temp file first to avoid corrupting the DB on failure
      final dbPath = await AppDatabase.databasePath;
      final tempPath = '$dbPath.tmp';
      final tempFile = File(tempPath);

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final sink = tempFile.openWrite();
      await for (final chunk in media.stream) {
        sink.add(chunk);
      }
      await sink.close();

      // Close the current DB before replacing the file
      await _db.close();

      // Replace the local DB with the downloaded file
      await tempFile.rename(dbPath);

      return 'success';
    } catch (_) {
      // Clean up temp file if it exists
      final dbPath = await AppDatabase.databasePath;
      final tempFile = File('$dbPath.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return 'error';
    } finally {
      client.close();
    }
  }

  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get the currently signed-in Google account without prompting UI.
  Future<GoogleSignInAccount?> getSignedInAccount() async {
    return _googleSignIn.signInSilently();
  }
}

/// Simple authenticated HTTP client wrapping an access token.
class _AuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _AuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
