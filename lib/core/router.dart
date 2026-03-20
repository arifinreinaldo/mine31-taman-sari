import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/pin_screen.dart';
import '../features/auth/screens/set_pin_screen.dart';
import '../features/products/screens/product_form_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/products/screens/stock_adjust_screen.dart';
import '../features/sales/screens/new_sale_screen.dart';
import '../features/sales/screens/sale_detail_screen.dart';
import '../features/sales/screens/sale_history_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final onAuthPage = state.matchedLocation == '/pin' ||
          state.matchedLocation == '/set-pin';

      if (!isAuthenticated && !onAuthPage) {
        return '/pin';
      }
      if (isAuthenticated && onAuthPage) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/pin',
        builder: (context, state) => const PinScreen(),
      ),
      GoRoute(
        path: '/set-pin',
        builder: (context, state) => const SetPinScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const ProductListScreen(),
                routes: [
                  GoRoute(
                    path: 'products/new',
                    builder: (context, state) => const ProductFormScreen(),
                  ),
                  GoRoute(
                    path: 'products/:id/edit',
                    builder: (context, state) => ProductFormScreen(
                      productId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'products/:id/stock',
                    builder: (context, state) => StockAdjustScreen(
                      productId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sale',
                builder: (context, state) => const NewSaleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const SaleHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => SaleDetailScreen(
                      transactionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'pin',
                    builder: (context, state) =>
                        const SetPinScreen(isChange: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'New Sale',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
