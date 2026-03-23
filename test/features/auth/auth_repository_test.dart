import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:per_taman_sari/features/auth/repositories/auth_repository.dart';

/// Fake [LocalAuthentication] for testing.
///
/// Uses [noSuchMethod] to handle platform-interface types that aren't
/// directly exported by local_auth.
class FakeLocalAuth extends Fake implements LocalAuthentication {
  bool deviceSupported;
  bool authenticateResult;

  FakeLocalAuth({
    this.deviceSupported = true,
    this.authenticateResult = true,
  });

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<bool> get canCheckBiometrics async => deviceSupported;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      return Future<bool>.value(authenticateResult);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('AuthRepository', () {
    test('authenticate returns true when device is not supported', () async {
      final fakeAuth = FakeLocalAuth(deviceSupported: false);
      final repo = AuthRepository(fakeAuth);

      expect(await repo.authenticate(), isTrue);
    });

    test('authenticate returns true on successful auth', () async {
      final fakeAuth = FakeLocalAuth(authenticateResult: true);
      final repo = AuthRepository(fakeAuth);

      expect(await repo.authenticate(), isTrue);
    });

    test('authenticate returns false on failed auth', () async {
      final fakeAuth = FakeLocalAuth(authenticateResult: false);
      final repo = AuthRepository(fakeAuth);

      expect(await repo.authenticate(), isFalse);
    });

    test('isDeviceSupported delegates to LocalAuthentication', () async {
      final fakeAuth = FakeLocalAuth(deviceSupported: true);
      final repo = AuthRepository(fakeAuth);
      expect(await repo.isDeviceSupported(), isTrue);

      fakeAuth.deviceSupported = false;
      expect(await repo.isDeviceSupported(), isFalse);
    });

    test('canCheckBiometrics delegates to LocalAuthentication', () async {
      final fakeAuth = FakeLocalAuth(deviceSupported: true);
      final repo = AuthRepository(fakeAuth);
      expect(await repo.canCheckBiometrics(), isTrue);

      fakeAuth.deviceSupported = false;
      expect(await repo.canCheckBiometrics(), isFalse);
    });
  });
}
