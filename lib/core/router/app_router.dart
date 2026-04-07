// lib/core/router/app_router.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial GoRouter + _RouterNotifier.
//   v2.0.0 — Booking flow routes (/bookings, /trainer/:id, /profile).
//            NotificationBannerHost wraps all authenticated routes.
//   v3.0.0 — Role-based routing (user → /home, trainer → /trainer-dashboard).
//            Firestore user role guard via firestoreUserProvider.
//   v3.1.0 — RECONCILED. Single source of truth:
//            • v2.0.0 booking flow + NotificationBannerHost retained.
//            • v3.0.0 role routing retained.
//            • TrainerProfileScreen import fixed to discover/ location.
//            • New routes: /trainers, /gyms, /wellness.
//            • /discover → redirect to /trainers (FABs + deep links still work).
//            • /availability → placeholder (AvailabilityScreen Week 5).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../landing_page.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/home_screen.dart';
import '../../features/discover/presentation/trainers_screen.dart';
import '../../features/discover/presentation/trainer_profile_screen.dart';
import '../../features/gyms/presentation/gyms_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/wellness/presentation/wellness_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/notifications/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const _kPublicRoutes = {'/', '/landing', '/login', '/signup'};

// ─────────────────────────────────────────────────────────────────────────────
// _RouterNotifier — fires on auth state OR Firestore user role change
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
    redirect: (context, state) {
      final loc = state.uri.path;

      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isLoggedIn = authAsync.value != null;
      final isPublicRoute = _kPublicRoutes.contains(loc);

      if (!isLoggedIn) return isPublicRoute ? null : '/login';

      final userAsync = ref.read(firestoreUserProvider);
      if (userAsync.isLoading) return null;

      final isTrainer = userAsync.value?.isTrainer == true;

      // Signed-in users bounce off public/landing routes.
      if (isPublicRoute) {
        return isTrainer ? '/trainer-dashboard' : '/home';
      }

      // Role enforcement — trainers can't access /home, users can't access
      // /trainer-dashboard. All other routes are accessible to both.
      if (loc == '/trainer-dashboard' && !isTrainer) return '/home';
      if (loc == '/home' && isTrainer) return '/trainer-dashboard';

      return null;
    },
    routes: [
      // ── PUBLIC ─────────────────────────────────────────────────────────────
      GoRoute(path: '/', redirect: (_, __) => '/landing'),
      GoRoute(
          path: '/landing',
          name: 'landing',
          builder: (_, __) => const LandingPage()),
      GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (_, __) => const SignupScreen()),

      // ── HOME ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => NotificationBannerHost(child: const HomeScreen()),
      ),

      // ── DISCOVER / TRAINERS ────────────────────────────────────────────────
      // /discover redirects to /trainers — FABs + existing deep links still work.
      GoRoute(path: '/discover', redirect: (_, __) => '/trainers'),
      GoRoute(
        path: '/trainers',
        name: 'trainers',
        builder: (_, __) =>
            NotificationBannerHost(child: const TrainersScreen()),
      ),

      // ── GYMS ───────────────────────────────────────────────────────────────
      GoRoute(
        path: '/gyms',
        name: 'gyms',
        builder: (_, __) => NotificationBannerHost(child: const GymsScreen()),
      ),

      // ── TRAINER PROFILE ────────────────────────────────────────────────────
      // Canonical source: discover/presentation/trainer_profile_screen.dart
      // The bookings/presentation/trainer_profile_screen.dart produced in the
      // previous session is superseded — do not import it.
      GoRoute(
        path: '/trainer/:id',
        name: 'trainerProfile',
        builder: (_, state) => NotificationBannerHost(
          child: TrainerProfileScreen(
            trainerId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),

      // ── BOOKINGS ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (_, __) =>
            NotificationBannerHost(child: const BookingsScreen()),
      ),

      // ── WELLNESS ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/wellness',
        name: 'wellness',
        builder: (_, __) =>
            NotificationBannerHost(child: const WellnessScreen()),
      ),

      // ── PROFILE + SETTINGS ────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) =>
            NotificationBannerHost(child: const ProfileScreen()),
      ),

      // ── TRAINER DASHBOARD ─────────────────────────────────────────────────
      GoRoute(
        path: '/trainer-dashboard',
        name: 'trainerDashboard',
        builder: (_, __) => NotificationBannerHost(
          child: const HomeScreen(isTrainerView: true),
        ),
      ),

      // ── TRAINER AVAILABILITY ──────────────────────────────────────────────
      // Placeholder — AvailabilityScreen ships Week 5.
      // The trainer FAB on HomeScreen(isTrainerView: true) routes here.
      GoRoute(
        path: '/availability',
        name: 'availability',
        builder: (_, __) => NotificationBannerHost(
          child: const _PlaceholderScreen(
            title: 'Manage Availability',
            icon: Icons.event_available_outlined,
            week: 'Week 5',
          ),
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF020E08),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined,
                color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text('Page not found',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text(state.uri.path,
                style: const TextStyle(color: Colors.white30, fontSize: 12)),
          ],
        ),
      ),
    ),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderScreen
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String week;
  const _PlaceholderScreen(
      {required this.title, required this.icon, required this.week});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF020E08),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          iconTheme: const IconThemeData(color: Colors.white54),
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white12, size: 56),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(color: Colors.white54, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Coming $week',
                style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ]),
        ),
      );
}
