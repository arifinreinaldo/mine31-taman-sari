import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taman_sari_pos/core/providers/core_providers.dart';
import 'package:taman_sari_pos/core/router.dart';
import 'package:taman_sari_pos/database/app_database.dart';
import 'package:taman_sari_pos/features/auth/providers/auth_provider.dart';
import 'package:taman_sari_pos/features/auth/repositories/auth_repository.dart';

/// A fake AuthRepository that never calls platform plugins.
class FakeAuthRepository extends AuthRepository {
  final bool shouldSucceed;

  FakeAuthRepository({this.shouldSucceed = false});

  @override
  Future<bool> authenticate() async => shouldSucceed;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> canCheckBiometrics() async => true;
}

/// Build the full app with router, overriding auth state, DB, and auth repo.
Widget _routerApp({
  required AppDatabase db,
  required bool isAuthenticated,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      isAuthenticatedProvider.overrideWith((ref) => isAuthenticated),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          routerConfig: router,
        );
      },
    ),
  );
}

/// Clean up: close DB outside fake-async zone, then dispose widget tree.
Future<void> _cleanup(WidgetTester tester, AppDatabase db) async {
  await tester.runAsync(() => db.close());
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  group('Router auth guard', () {
    testWidgets('redirects to PIN screen when unauthenticated',
        (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(_routerApp(db: db, isAuthenticated: false));
      await tester.pump();
      await tester.pump();

      // Should see the auth/PIN screen content
      expect(find.text('Taman Sari POS'), findsOneWidget);
      expect(find.text('Authenticate to continue'), findsOneWidget);

      await _cleanup(tester, db);
    });

    testWidgets('shows main screen when authenticated', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(_routerApp(db: db, isAuthenticated: true));
      await tester.pump();
      await tester.pump();

      // Should see the bottom nav with Products tab
      expect(find.text('Products'), findsWidgets);

      await _cleanup(tester, db);
    });

    testWidgets('shows bottom navigation bar when authenticated',
        (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(_routerApp(db: db, isAuthenticated: true));
      await tester.pump();
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('New Sale'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await _cleanup(tester, db);
    });

    testWidgets('does not show bottom nav on PIN screen', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(_routerApp(db: db, isAuthenticated: false));
      await tester.pump();
      await tester.pump();

      expect(find.byType(NavigationBar), findsNothing);

      await _cleanup(tester, db);
    });
  });

  group('Tab navigation', () {
    testWidgets('can navigate between tabs', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(_routerApp(db: db, isAuthenticated: true));
      await tester.pump();
      await tester.pump();

      // Tap on History tab
      await tester.tap(find.text('History'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sales History'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Google Drive Backup'), findsOneWidget);

      // Tap back to Products tab
      await tester.tap(find.text('Products').last);
      await tester.pump();
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await _cleanup(tester, db);
    });
  });
}
