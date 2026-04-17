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
//   v3.1.0 — RECONCILED. Single source of truth.
//            • /trainers, /gyms, /wellness added.
//            • /discover → redirect to /trainers.
//            • /availability placeholder (Week 5).
//   v3.2.0 — Marketing split: /landing, /dev, /about, /features, /pricing.
//   v3.3.0 — Admin routes: /admin, /admin/content, /admin/brand,
//            /admin/features, /admin/preview. Each wrapped in QAdminShell.
//   v3.4.0 — Admin login flow + proper admin route protection:
//            • /admin-login added (AdminLoginScreen) — public.
//            • /admin removed from _kPublicRoutes (now protected).
//            • isAdminRoute helper: true for /admin and all /admin/* paths.
//            • Full redirect matrix documented below.
//   v3.4.1 — /admin/trainers added → ScreenAdminTrainers in QAdminShell.
//   v3.4.2 — Admin live-page preview support:
//            • Admins are no longer redirected away from public/marketing routes.
//              Previously, isPublicRoute → redirect admin to /admin, which made
//              clicking "Preview Landing Page" from the overview a redirect loop.
//              Now: admins pass through public routes freely (for preview).
//            • /admin-login is special-cased in the public-route block:
//              already-authenticated users (of any role) are sent to their home
//              screen, so they never see the admin login form twice.
//            • Role enforcement (/home ↔ /trainer-dashboard) only applies to
//              non-admin users — admins can visit both for preview purposes.
// ─────────────────────────────────────────────────────────────────────────────
//
// REDIRECT MATRIX (v3.4.2):
//
//   Auth state     │ Route type        │ Result
//   ───────────────┼───────────────────┼────────────────────────────────
//   Not logged in  │ Admin route       │ → /admin-login
//   Not logged in  │ Public route      │ Pass through
//   Not logged in  │ Protected route   │ → /login
//   ───────────────┼───────────────────┼────────────────────────────────
//   Admin          │ /admin-login      │ → /admin   (already logged in)
//   Admin          │ Any public route  │ Pass through  (live preview)
//   Admin          │ Admin route       │ Pass through
//   Admin          │ Any other route   │ Pass through  (preview /home etc.)
//   ───────────────┼───────────────────┼────────────────────────────────
//   Trainer        │ /admin-login      │ → /trainer-dashboard
//   Trainer        │ Other public      │ → /trainer-dashboard
//   Trainer        │ Admin route       │ → /home
//   Trainer        │ /home             │ → /trainer-dashboard
//   ───────────────┼───────────────────┼────────────────────────────────
//   User (regular) │ /admin-login      │ → /home
//   User           │ Other public      │ → /home
//   User           │ Admin route       │ → /home
//   User           │ /trainer-dash     │ → /home

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Public / marketing screens ─────────────────────────────────────────────
import '../../spaces/space_site/screen_home/screen_home_main.dart';
import '../../dev_landing_page.dart';
import '../../spaces/space_site/screen_about/about_screen.dart';
import '../../spaces/space_site/screen_features/features_screen.dart';
import '../../spaces/space_site/screen_pricing/pricing_screen.dart';

// ── Auth screens ────────────────────────────────────────────────────────────
import '../../spaces/auth/presentation/login_screen.dart';
import '../../spaces/auth/presentation/signup_screen.dart';
import '../../spaces/auth/presentation/admin_login_screen.dart';
import '../../spaces/auth/providers/auth_providers.dart';

// ── Authenticated screens ───────────────────────────────────────────────────
import '../../spaces/dashboard/home_screen.dart';
import '../../spaces/discover/presentation/trainers_screen.dart';
import '../../spaces/discover/presentation/trainer_profile_screen.dart';
import '../../spaces/gyms/presentation/gyms_screen.dart';
import '../../spaces/bookings/presentation/bookings_screen.dart';
import '../../spaces/wellness/presentation/wellness_screen.dart';
import '../../spaces/profile/presentation/profile_screen.dart';
import '../../spaces/notifications/notification_service.dart';

// ── Admin space ─────────────────────────────────────────────────────────────
import '../../core/admin/q_admin_shell.dart';
import '../../core/admin/screens/screen_admin_overview.dart';
import '../../core/admin/screens/screen_admin_content.dart';
import '../../core/admin/screens/screen_admin_brand.dart';
import '../../core/admin/screens/screen_admin_features.dart';
import '../../core/admin/screens/screen_admin_preview.dart';
import '../../core/admin/screens/screen_admin_trainers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

/// Routes that never require Firebase Auth.
///
/// '/admin' is deliberately NOT in this set — admin routes are protected.
/// Unauthenticated visitors → /admin-login; authenticated non-admins → /home.
///
/// '/admin-login' IS listed — it's the entry point for the admin flow and must
/// be reachable with no prior session.
const _kPublicRoutes = {
  '/',
  '/landing',
  '/about',
  '/features',
  '/pricing',
  '/login',
  '/signup',
  '/admin-login',
  '/dev',
};

// ─────────────────────────────────────────────────────────────────────────────
// _RouterNotifier — fires on auth state OR Firestore user role change
// ─────────────────────────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider,    (_, __) => notifyListeners());
    ref.listen(firestoreUserProvider,(_, __) => notifyListeners());
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

      // ── Auth state ─────────────────────────────────────────────────────
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isLoggedIn    = authAsync.value != null;
      final isPublicRoute = _kPublicRoutes.contains(loc);

      // isAdminRoute: true for /admin and /admin/* sub-paths.
      // '/admin-login' does NOT match — it starts with '/admin-' not '/admin/'.
      final isAdminRoute = loc == '/admin' || loc.startsWith('/admin/');

      // ── Not logged in ──────────────────────────────────────────────────
      if (!isLoggedIn) {
        if (isAdminRoute)  return '/admin-login'; // admin routes → admin gate
        if (isPublicRoute) return null;            // public routes → pass through
        return '/login';                           // protected routes → user gate
      }

      // ── Logged in: resolve user role ───────────────────────────────────
      final userAsync = ref.read(firestoreUserProvider);
      if (userAsync.isLoading) return null;

      final isAdmin   = userAsync.value?.isAdmin   == true;
      final isTrainer = userAsync.value?.isTrainer  == true;

      // ── Public-route handling for authenticated users ───────────────────
      if (isPublicRoute) {
        // /admin-login: already authenticated — don't show the login form.
        // Send each role to its canonical home screen.
        if (loc == '/admin-login') {
          if (isAdmin)   return '/admin';
          if (isTrainer) return '/trainer-dashboard';
          return '/home';
        }

        // Admins may browse any public/marketing page freely.
        // This is intentional — it enables live-page preview from the admin
        // dashboard (ScreenAdminOverview "Preview Live Pages" actions navigate
        // to /landing, /home, etc. and must not bounce back to /admin).
        if (isAdmin) return null;

        // Non-admin authenticated users go to their respective home screens.
        if (isTrainer) return '/trainer-dashboard';
        return '/home';
      }

      // ── Admin routes: require 'admin' role ─────────────────────────────
      // Non-admins who type an admin URL directly → /home, not /admin-login.
      // They are authenticated; showing the login form again would be wrong.
      if (isAdminRoute && !isAdmin) return '/home';

      // ── Role enforcement for regular app routes ─────────────────────────
      // Only applies to non-admin users. Admins can visit /home and
      // /trainer-dashboard freely (e.g. to preview the trainer experience).
      if (!isAdmin) {
        if (loc == '/trainer-dashboard' && !isTrainer) return '/home';
        if (loc == '/home' && isTrainer)               return '/trainer-dashboard';
      }

      // All other cases — pass through.
      return null;
    },
    routes: [

      // ── ROOT ──────────────────────────────────────────────────────────────
      GoRoute(path: '/', redirect: (_, __) => '/landing'),

      // ── MARKETING — PUBLIC ─────────────────────────────────────────────────
      GoRoute(
        path:    '/landing',
        name:    'landing',
        builder: (ctx, state) => const SiteLandingPage(),
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
      GoRoute(
        path:    '/dev',
        name:    'devLanding',
        builder: (_, __) => const DevLandingPage(),
      ),

      // ── AUTH ───────────────────────────────────────────────────────────────
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
      // Admin login — dedicated entry point, visually distinct from /login.
      // Two-stage auth: Firebase signIn() + Firestore role == 'admin' check.
      GoRoute(
        path:    '/admin-login',
        name:    'adminLogin',
        builder: (_, __) => const AdminLoginScreen(),
      ),

      // ── HOME ───────────────────────────────────────────────────────────────
      GoRoute(
        path:    '/home',
        name:    'home',
        builder: (_, __) => NotificationBannerHost(child: const HomeScreen()),
      ),

      // ── DISCOVER / TRAINERS ────────────────────────────────────────────────
      GoRoute(path: '/discover', redirect: (_, __) => '/trainers'),
      GoRoute(
        path:    '/trainers',
        name:    'trainers',
        builder: (_, __) => NotificationBannerHost(child: const TrainersScreen()),
      ),

      // ── GYMS ───────────────────────────────────────────────────────────────
      GoRoute(
        path:    '/gyms',
        name:    'gyms',
        builder: (_, __) => NotificationBannerHost(child: const GymsScreen()),
      ),

      // ── TRAINER PROFILE ────────────────────────────────────────────────────
      GoRoute(
        path:    '/trainer/:id',
        name:    'trainerProfile',
        builder: (_, state) => NotificationBannerHost(
          child: TrainerProfileScreen(
            trainerId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),

      // ── BOOKINGS ───────────────────────────────────────────────────────────
      GoRoute(
        path:    '/bookings',
        name:    'bookings',
        builder: (_, __) => NotificationBannerHost(child: const BookingsScreen()),
      ),

      // ── WELLNESS ───────────────────────────────────────────────────────────
      GoRoute(
        path:    '/wellness',
        name:    'wellness',
        builder: (_, __) => NotificationBannerHost(child: const WellnessScreen()),
      ),

      // ── PROFILE + SETTINGS ─────────────────────────────────────────────────
      GoRoute(
        path:    '/profile',
        name:    'profile',
        builder: (_, __) => NotificationBannerHost(child: const ProfileScreen()),
      ),

      // ── ADMIN ──────────────────────────────────────────────────────────────
      // All routes below are PROTECTED (role == 'admin') by the redirect guard.
      // QAdminShell wraps each screen with sidebar + publish toolbar.
      GoRoute(
        path:    '/admin',
        name:    'adminOverview',
        builder: (_, __) => QAdminShell(child: ScreenAdminOverview()),
      ),
      GoRoute(
        path:    '/admin/content',
        name:    'adminContent',
        builder: (_, __) => QAdminShell(child: ScreenAdminContent()),
      ),
      GoRoute(
        path:    '/admin/brand',
        name:    'adminBrand',
        builder: (_, __) => QAdminShell(child: ScreenAdminBrand()),
      ),
      GoRoute(
        path:    '/admin/features',
        name:    'adminFeatures',
        builder: (_, __) => QAdminShell(child: ScreenAdminFeatures()),
      ),
      GoRoute(
        path:    '/admin/preview',
        name:    'adminPreview',
        builder: (_, __) => QAdminShell(child: ScreenAdminPreview()),
      ),
      GoRoute(
        path:    '/admin/trainers',
        name:    'adminTrainers',
        builder: (_, __) => QAdminShell(child: ScreenAdminTrainers()),
      ),

      // ── TRAINER DASHBOARD ──────────────────────────────────────────────────
      GoRoute(
        path:    '/trainer-dashboard',
        name:    'trainerDashboard',
        builder: (_, __) => NotificationBannerHost(
          child: const HomeScreen(isTrainerView: true),
        ),
      ),

      // ── TRAINER AVAILABILITY ───────────────────────────────────────────────
      // Placeholder — AvailabilityScreen ships Week 5.
      GoRoute(
        path: '/availability',
        name: 'availability',
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

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.week,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF020E08),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation:       0,
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