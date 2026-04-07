// lib/core/router/app_router.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v3.0.0 — Unified router:
//            • Riverpod-driven auth + Firestore role routing
//            • NotificationBannerHost preserved across protected routes
//            • Full booking flow retained
//            • Trainer vs User role enforcement
//            • No split-brain (single source of truth)
//            • Placeholder fallback only where needed
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../landing_page.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

import '../../features/home/home_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';

import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/bookings/presentation/trainer_profile_screen.dart';

import '../../features/profile/presentation/profile_screen.dart';

import '../../features/notifications/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const _kPublicRoutes = {'/', '/landing', '/login', '/signup'};

// ─────────────────────────────────────────────────────────────────────────────
// _RouterNotifier
// ─────────────────────────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(firestoreUserProvider, (_, __) => notifyListeners());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// routerProvider
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/landing',
    refreshListenable: notifier,

    // ─────────────────────────────────────────────────────────────────────────
    // REDIRECT LOGIC (AUTH + ROLE)
    // ─────────────────────────────────────────────────────────────────────────
    redirect: (context, state) {
      final loc = state.uri.path;

      // 1. Wait for auth state
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isLoggedIn = authAsync.value != null;
      final isPublicRoute = _kPublicRoutes.contains(loc);

      // 2. Signed out
      if (!isLoggedIn) {
        return isPublicRoute ? null : '/login';
      }

      // 3. Wait for user role
      final userAsync = ref.read(firestoreUserProvider);
      if (userAsync.isLoading) return null;

      final user = userAsync.value;
      final isTrainer = user?.isTrainer == true;

      // 4. Signed in → redirect away from public routes
      if (isPublicRoute) {
        return isTrainer ? '/trainer-dashboard' : '/home';
      }

      // 5. Role enforcement
      if (loc == '/trainer-dashboard' && !isTrainer) return '/home';
      if (loc == '/home' && isTrainer) return '/trainer-dashboard';

      return null;
    },

    // ─────────────────────────────────────────────────────────────────────────
    // ROUTES
    // ─────────────────────────────────────────────────────────────────────────
    routes: [
      // ── PUBLIC ─────────────────────────────────────────────────────────────

      GoRoute(
        path: '/',
        redirect: (_, __) => '/landing',
      ),

      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (_, __) => const LandingPage(),
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignupScreen(),
      ),

      // ── PROTECTED: USER ────────────────────────────────────────────────────

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => NotificationBannerHost(
          child: const HomeScreen(),
        ),
      ),

      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (_, __) => NotificationBannerHost(
          child: const DiscoverScreen(),
        ),
      ),

      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (_, __) => NotificationBannerHost(
          child: const BookingsScreen(),
        ),
      ),

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => NotificationBannerHost(
          child: const ProfileScreen(),
        ),
      ),

      GoRoute(
        path: '/wellness',
        name: 'wellness',
        builder: (_, __) => NotificationBannerHost(
          child: const _PlaceholderScreen(
            title: 'Track Wellness',
            icon: Icons.favorite_outline,
            week: 'Week 5',
          ),
        ),
      ),

      // ── PROTECTED: TRAINER ─────────────────────────────────────────────────

      GoRoute(
        path: '/trainer-dashboard',
        name: 'trainerDashboard',
        builder: (_, __) => NotificationBannerHost(
          child: const HomeScreen(isTrainerView: true),
        ),
      ),

      GoRoute(
        path: '/availability',
        name: 'availability',
        builder: (_, __) => NotificationBannerHost(
          child: const HomeScreen(isTrainerView: true), // replace later
        ),
      ),

      // ── TRAINER PROFILE (PUBLIC ACCESSIBLE) ────────────────────────────────

      GoRoute(
        path: '/trainer/:id',
        name: 'trainerProfile',
        builder: (_, state) => NotificationBannerHost(
          child: TrainerProfileScreen(
            trainerId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
    ],

    // ─────────────────────────────────────────────────────────────────────────
    // ERROR PAGE
    // ─────────────────────────────────────────────────────────────────────────
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF020E08),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined,
                color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.path,
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String week;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.week,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020E08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white54),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white12, size: 56),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(color: Colors.white54, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Coming $week',
              style: const TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
