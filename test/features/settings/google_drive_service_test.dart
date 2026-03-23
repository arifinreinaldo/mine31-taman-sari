import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/core/constants.dart';
import 'package:per_taman_sari/database/app_database.dart';
import 'package:per_taman_sari/features/settings/services/google_drive_service.dart';

void main() {
  late AppDatabase db;
  late GoogleDriveService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = GoogleDriveService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('shouldAutoBackup', () {
    test('returns true when no backup has ever been made', () async {
      expect(await service.shouldAutoBackup(), isTrue);
    });

    test('returns true when last backup is older than 24 hours', () async {
      final oldDate =
          DateTime.now().subtract(const Duration(hours: 25));
      await db.setMetadata(MetaKeys.lastBackup, oldDate.toIso8601String());

      expect(await service.shouldAutoBackup(), isTrue);
    });

    test('returns false when last backup is within 24 hours', () async {
      final recentDate =
          DateTime.now().subtract(const Duration(hours: 1));
      await db.setMetadata(
        MetaKeys.lastBackup,
        recentDate.toIso8601String(),
      );

      expect(await service.shouldAutoBackup(), isFalse);
    });

    test('returns true when metadata value is invalid date string', () async {
      await db.setMetadata(MetaKeys.lastBackup, 'not-a-date');

      expect(await service.shouldAutoBackup(), isTrue);
    });

    test('returns false when last backup is just under 24 hours ago',
        () async {
      final justUnder =
          DateTime.now().subtract(const Duration(hours: 23, minutes: 59));
      await db.setMetadata(
        MetaKeys.lastBackup,
        justUnder.toIso8601String(),
      );

      expect(await service.shouldAutoBackup(), isFalse);
    });
  });
}
