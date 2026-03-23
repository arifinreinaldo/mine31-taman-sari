import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Whether the user has unlocked the app this session.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);
