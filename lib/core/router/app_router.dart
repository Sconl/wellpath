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
//   v3.2.0 — Production landing page split:
//            • /landing → new LandingPage (production marketing)
//            • /dev     → DevLandingPage (original roadmap / developer preview)
//            • /about   → AboutScreen
//            • /features → FeaturesScreen
//            • /pricing  → PricingScreen
//            All three marketing pages added to _kPublicRoutes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Public / marketing screens ────────────────────────────────────────────────
import '../../landing_page.dart';
import '../../dev_landing_page.dart';
import '../../features/site/about/about_screen.dart';
import '../../features/site/features_page/features_screen.dart';
import '../../features/site/pricing/pricing_screen.dart';

// ── Auth screens ──────────────────────────────────────────────────────────────
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

// ── Authenticated screens ─────────────────────────────────────────────────────
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

/// Routes that never require authentication.
/// Auth redirect logic only redirects to /login for routes NOT in this set.
const _kPublicRoutes = {
  '/',
  '/landing',
  '/about',
  '/features',
  '/pricing',
  '/login',
  '/signup',
  '/dev',
};

// ─────────────────────────────────────────────────────────────────────────────
// _RouterNotifier — fires on auth state OR Firestore user role change
// ─────────────────────────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider,      (_, __) => notifyListeners());
    ref.listen(firestoreUserProvider,  (_, __) => notifyListeners());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// routerProvider
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation:     '/landing',
    refreshListenable:   notifier,

    redirect: (context, state) {
      final loc = state.uri.path;

      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isLoggedIn    = authAsync.value != null;
      final isPublicRoute = _kPublicRoutes.contains(loc);

      // Not logged in: public routes pass through, protected routes → /login.
      if (!isLoggedIn) return isPublicRoute ? null : '/login';

      // Wait for Firestore user data to resolve.
      final userAsync = ref.read(firestoreUserProvider);
      if (userAsync.isLoading) return null;
      final isTrainer = userAsync.value?.isTrainer == true;

      // Logged-in users on public/landing routes → their home screen.
      if (isPublicRoute) {
        return isTrainer ? '/trainer-dashboard' : '/home';
      }

      // Role enforcement.
      if (loc == '/trainer-dashboard' && !isTrainer) return '/home';
      if (loc == '/home' && isTrainer) return '/trainer-dashboard';

      return null;
    },

    routes: [

      // ── ROOT ─────────────────────────────────────────────────────────────
      GoRoute(path: '/', redirect: (_, __) => '/landing'),

      // ── MARKETING — PUBLIC ────────────────────────────────────────────────

      GoRoute(
        path:    '/landing',
        name:    'landing',
        builder: (_, __) => const LandingPage(),
      ),

      GoRoute(
        path:    '/about',
        name:    'about',
        builder: (_, __) => const AboutScreen(),
      ),

      GoRoute(
        path:    '/features',
        name:    'features',
        builder: (_, __) => const FeaturesScreen(),
      ),

      GoRoute(
        path:    '/pricing',
        name:    'pricing',
        builder: (_, __) => const PricingScreen(),
      ),

      // Developer roadmap page (accessible from production landing footer)
      GoRoute(
        path:    '/dev',
        name:    'devLanding',
        builder: (_, __) => const DevLandingPage(),
      ),

      // ── AUTH ──────────────────────────────────────────────────────────────

      GoRoute(
        path:    '/login',
        name:    'login',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path:    '/signup',
        name:    'signup',
        builder: (_, __) => const SignupScreen(),
      ),

      // ── HOME ─────────────────────────────────────────────────────────────

      GoRoute(
        path:    '/home',
        name:    'home',
        builder: (_, __) => NotificationBannerHost(child: const HomeScreen()),
      ),

      // ── DISCOVER / TRAINERS ───────────────────────────────────────────────
      // /discover redirects to /trainers — FABs + deep links remain valid.
      GoRoute(path: '/discover', redirect: (_, __) => '/trainers'),

      GoRoute(
        path:    '/trainers',
        name:    'trainers',
        builder: (_, __) => NotificationBannerHost(child: const TrainersScreen()),
      ),

      // ── GYMS ─────────────────────────────────────────────────────────────

      GoRoute(
        path:    '/gyms',
        name:    'gyms',
        builder: (_, __) => NotificationBannerHost(child: const GymsScreen()),
      ),

      // ── TRAINER PROFILE ───────────────────────────────────────────────────
      // Canonical source: discover/presentation/trainer_profile_screen.dart

      GoRoute(
        path:    '/trainer/:id',
        name:    'trainerProfile',
        builder: (_, state) => NotificationBannerHost(
          child: TrainerProfileScreen(
            trainerId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),

      // ── BOOKINGS ──────────────────────────────────────────────────────────

      GoRoute(
        path:    '/bookings',
        name:    'bookings',
        builder: (_, __) => NotificationBannerHost(child: const BookingsScreen()),
      ),

      // ── WELLNESS ─────────────────────────────────────────────────────────

      GoRoute(
        path:    '/wellness',
        name:    'wellness',
        builder: (_, __) => NotificationBannerHost(child: const WellnessScreen()),
      ),

      // ── PROFILE + SETTINGS ────────────────────────────────────────────────

      GoRoute(
        path:    '/profile',
        name:    'profile',
        builder: (_, __) => NotificationBannerHost(child: const ProfileScreen()),
      ),

      // ── TRAINER DASHBOARD ─────────────────────────────────────────────────

      GoRoute(
        path:    '/trainer-dashboard',
        name:    'trainerDashboard',
        builder: (_, __) => NotificationBannerHost(
          child: const HomeScreen(isTrainerView: true),
        ),
      ),

      // ── TRAINER AVAILABILITY ─────────────────────────────────────────────
      // Placeholder — AvailabilityScreen ships Week 5.

      GoRoute(
        path:    '/availability',
        name:    'availability',
        builder: (_, __) => NotificationBannerHost(
          child: const _PlaceholderScreen(
            title: 'Manage Availability',
            icon:  Icons.event_available_outlined,
            week:  'Week 5',
          ),
        ),
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF020E08),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.link_off_outlined, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          const Text('Page not found',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(state.uri.path,
              style: const TextStyle(color: Colors.white30, fontSize: 12)),
        ]),
      ),
    ),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderScreen
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String   title;
  final IconData icon;
  final String   week;
  const _PlaceholderScreen({required this.title, required this.icon, required this.week});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF020E08),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation:       0,
      title:       Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      iconTheme:   const IconThemeData(color: Colors.white54),
    ),
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white12, size: 56),
        const SizedBox(height: 20),
        Text(title,    style: const TextStyle(color: Colors.white54, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Coming $week', style: const TextStyle(color: Colors.white24, fontSize: 12)),
      ]),
    ),
  );
}