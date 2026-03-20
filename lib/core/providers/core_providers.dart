import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';

/// Database provider — overridden in ProviderScope with the real instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});
