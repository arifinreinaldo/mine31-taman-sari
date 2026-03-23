import 'package:local_auth/local_auth.dart';

class AuthRepository {
  final LocalAuthentication _localAuth;

  AuthRepository([LocalAuthentication? localAuth])
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Whether the device supports any form of authentication
  /// (biometric or device credentials like PIN/pattern/password).
  Future<bool> isDeviceSupported() => _localAuth.isDeviceSupported();

  /// Whether biometrics are specifically available (enrolled fingerprint/face).
  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  /// Prompt the user to authenticate via biometrics or device credentials.
  /// Returns true if authentication succeeded.
  Future<bool> authenticate() async {
    final supported = await _localAuth.isDeviceSupported();
    if (!supported) return true; // No lock screen set — allow access

    return _localAuth.authenticate(
      localizedReason: 'Unlock Taman Sari POS',
      options: const AuthenticationOptions(
        biometricOnly: false, // Allow device PIN/pattern/password fallback
        stickyAuth: true,
      ),
    );
  }
}
