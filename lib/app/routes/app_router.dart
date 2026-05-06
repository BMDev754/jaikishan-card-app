import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/home/main_navigation_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/profile/account_screen.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isLoggedIn;
      final isInitialized = authProvider.isInitialized;
      
      // If not initialized yet, stay on current route
      if (!isInitialized) {
        return null;
      }
      
      // If going to splash, let it handle the navigation
      if (state.matchedLocation == '/splash') {
        return null;
      }
      
      // If user is not logged in and trying to access protected routes
      if (!isLoggedIn && state.matchedLocation != '/login') {
        return '/login';
      }
      
      // If user is logged in and trying to access login
      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Login Screen
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Home Route (Main Navigation)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      
      // Account Screen
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
    ],
  );
}
