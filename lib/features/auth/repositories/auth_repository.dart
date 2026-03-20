import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../core/constants.dart';
import '../../../database/app_database.dart';

class AuthRepository {
  final AppDatabase _db;

  AuthRepository(this._db);

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Returns true if a PIN has been set.
  Future<bool> hasPinSet() async {
    final value = await _db.getMetadata(MetaKeys.pinHash);
    return value != null && value.isNotEmpty;
  }

  /// Verify a PIN against the stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _db.getMetadata(MetaKeys.pinHash);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  /// Set (or change) the PIN.
  Future<void> setPin(String pin) async {
    await _db.setMetadata(MetaKeys.pinHash, _hashPin(pin));
  }
}
