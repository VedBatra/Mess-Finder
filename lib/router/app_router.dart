// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/mess_detail_screen.dart';
import '../screens/user/checkout_screen.dart';
import '../screens/user/order_tracking_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';
import '../screens/owner/owner_orders_screen.dart';
import '../screens/owner/owner_mess_editor_screen.dart';
import '../screens/owner/owner_menu_editor_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../utils/constants.dart';

/// A ChangeNotifier that listens to auth state and tells GoRouter
/// to re-evaluate its redirect without recreating the router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(authProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      // Read the current auth state
      final authState = ref.read(authProvider);
      
      debugPrint('Router Redirect: location=${state.matchedLocation}, authLoading=${authState.isLoading}, hasError=${authState.hasError}, hasProfile=${authState.valueOrNull != null}');

      if (authState.isLoading) return null;

      final profile = authState.valueOrNull;
      final isLoggedIn = profile != null;
      final location = state.matchedLocation;

      final authRoutes = ['/login', '/signup'];
      final isOnAuthPage = authRoutes.contains(location);

      // Special case: if there's an error and we're not on auth page, go back to login
      if (authState.hasError && !isOnAuthPage) {
        debugPrint('Router: Auth error detected, redirecting to /login');
        return '/login';
      }

      // Not logged in → force to login (but let splash '/' through)
      if (!isLoggedIn && !isOnAuthPage && location != '/') {
        // Double check if actually authenticated with Supabase but just missing profile
        final hasSession = ref.read(authServiceProvider).currentUser != null;
        if (hasSession && !isLoggedIn) {
          debugPrint('Router: Authenticated but no profile record found.');
          // For now, let them stay on login or we could redirect to a profile setup page
        }
        return '/login';
      }

      // Logged in but on auth page or splash → redirect to role-based home
      if (isLoggedIn && (isOnAuthPage || location == '/')) {
        switch (profile.role) {
          case AppConstants.roleOwner:
            return '/owner';
          case AppConstants.roleAdmin:
            return '/admin';
          default:
            return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // User routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mess/:id',
        builder: (context, state) =>
            MessDetailScreen(messId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkout/:messId',
        builder: (context, state) => CheckoutScreen(
          messId: state.pathParameters['messId']!,
          mealType: state.uri.queryParameters['meal'] ?? 'lunch',
        ),
      ),
      GoRoute(
        path: '/tracking/:orderId',
        builder: (context, state) =>
            OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Owner routes
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/orders',
        builder: (context, state) => const OwnerOrdersScreen(),
      ),
      GoRoute(
        path: '/owner/edit-mess',
        builder: (context, state) => const OwnerMessEditorScreen(),
      ),
      GoRoute(
        path: '/owner/menu',
        builder: (context, state) => const OwnerMenuEditorScreen(),
      ),
      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
