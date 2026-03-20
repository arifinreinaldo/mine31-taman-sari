import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taman_sari_pos/database/app_database.dart';
import 'package:taman_sari_pos/features/auth/repositories/auth_repository.dart';

void main() {
  late AppDatabase db;
  late AuthRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AuthRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AuthRepository', () {
    test('hasPinSet returns false initially', () async {
      expect(await repo.hasPinSet(), isFalse);
    });

    test('setPin then hasPinSet returns true', () async {
      await repo.setPin('1234');
      expect(await repo.hasPinSet(), isTrue);
    });

    test('verifyPin returns false when no pin set', () async {
      expect(await repo.verifyPin('1234'), isFalse);
    });

    test('verifyPin returns true for correct pin', () async {
      await repo.setPin('1234');
      expect(await repo.verifyPin('1234'), isTrue);
    });

    test('verifyPin returns false for wrong pin', () async {
      await repo.setPin('1234');
      expect(await repo.verifyPin('0000'), isFalse);
    });

    test('setPin overwrites previous pin', () async {
      await repo.setPin('1234');
      await repo.setPin('5678');
      expect(await repo.verifyPin('1234'), isFalse);
      expect(await repo.verifyPin('5678'), isTrue);
    });

    test('pin hash is deterministic', () async {
      await repo.setPin('abcd');
      expect(await repo.verifyPin('abcd'), isTrue);
    });

    test('different pins produce different hashes', () async {
      await repo.setPin('1234');
      expect(await repo.verifyPin('1235'), isFalse);
    });
  });
}
