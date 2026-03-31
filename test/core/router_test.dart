import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:per_taman_sari/core/router.dart';
import 'package:per_taman_sari/features/auth/providers/auth_provider.dart';
import 'package:per_taman_sari/features/auth/repositories/auth_repository.dart';
import 'package:per_taman_sari/features/products/providers/product_providers.dart';
import 'package:per_taman_sari/features/sales/providers/transaction_providers.dart';
import 'package:per_taman_sari/features/settings/providers/settings_providers.dart';

/// A fake AuthRepository that never calls platform plugins.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository();

  @override
  Future<bool> authenticate() async => false;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> canCheckBiometrics() async => true;
}

/// Build the full app with router, overriding providers to avoid real DB.
Widget _routerApp({required bool isAuthenticated}) {
  return ProviderScope(
    overrides: [
      isAuthenticatedProvider.overrideWith((ref) => isAuthenticated),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      productListProvider.overrideWith((ref) => Stream.value([])),
      transactionListProvider.overrideWith((ref) => Stream.value([])),
      lastBackupProvider.overrideWith((ref) async => null),
      lastExportProvider.overrideWith((ref) async => null),
      googleAccountProvider.overrideWith((ref) async => null),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  group('Router auth guard', () {
    testWidgets('redirects to PIN screen when unauthenticated',
        (tester) async {
      await tester.pumpWidget(_routerApp(isAuthenticated: false));
      await tester.pumpAndSettle();

      expect(find.text('Taman Sari POS'), findsOneWidget);
      expect(find.text('Sentuh untuk masuk'), findsOneWidget);
    });

    testWidgets('shows main screen when authenticated', (tester) async {
      await tester.pumpWidget(_routerApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      expect(find.text('Produk'), findsWidgets);
    });

    testWidgets('shows bottom navigation bar when authenticated',
        (tester) async {
      await tester.pumpWidget(_routerApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Penjualan'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
    });

    testWidgets('does not show bottom nav on PIN screen', (tester) async {
      await tester.pumpWidget(_routerApp(isAuthenticated: false));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('Tab navigation', () {
    testWidgets('can navigate between tabs', (tester) async {
      await tester.pumpWidget(_routerApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Tap on History tab
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Penjualan'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.text('Cadangan Google Drive'), findsOneWidget);

      // Tap back to Products tab
      await tester.tap(find.text('Produk').last);
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
