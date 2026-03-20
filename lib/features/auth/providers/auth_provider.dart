import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(databaseProvider));
});

/// Whether the user has unlocked the app this session.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Whether a PIN has been set at all.
final hasPinSetProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authRepositoryProvider).hasPinSet();
});
