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
//   v3.3.0 — Admin routes added:
//            • /admin
//            • /admin/content
//            • /admin/brand
//            • /admin/features
//            • /admin/preview
//            Each route is wrapped in QAdminShell.
//   v3.4.0 — Admin login flow + proper admin route protection:
//            • /admin-login route added (AdminLoginScreen) — public.
//            • /admin removed from _kPublicRoutes — it is now a PROTECTED route.
//            • New helper isAdminRoute: true for /admin and all /admin/* paths.
//            • Redirect logic restructured with explicit admin cases:
//                – Not logged in + admin route       → /admin-login
//                – Not logged in + public route      → pass through
//                – Not logged in + protected route   → /login
//                – Logged in admin + public route    → /admin
//                – Logged in admin + admin route     → pass through
//                – Logged in non-admin + admin route → /home (not /admin-login,
//                  because they ARE authenticated — they just lack the role)
//                – Logged in trainer + /home         → /trainer-dashboard
//                – Logged in user + /trainer-dash    → /home
//            • Footer admin link updated: routes to /admin-login not /admin.
//              This means clicking "Admin" always shows the admin login screen
//              first — even if you're already logged in as a regular user,
//              you'll be bounced to /home via the redirect. Clean.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Public / marketing screens ────────────────────────────────────────────────
import '../../spaces/space_site/screen_home/screen_home_main.dart';
import '../../dev_landing_page.dart';
import '../../spaces/space_site/screen_about/about_screen.dart';
import '../../spaces/space_site/screen_features/features_screen.dart';
import '../../spaces/space_site/screen_pricing/pricing_screen.dart';

// ── Auth screens ──────────────────────────────────────────────────────────────
import '../../spaces/auth/presentation/login_screen.dart';
import '../../spaces/auth/presentation/signup_screen.dart';
import '../../spaces/auth/presentation/admin_login_screen.dart';
import '../../spaces/auth/providers/auth_providers.dart';

// ── Authenticated screens ─────────────────────────────────────────────────────
import '../../spaces/dashboard/home_screen.dart';
import '../../spaces/discover/presentation/trainers_screen.dart';
import '../../spaces/discover/presentation/trainer_profile_screen.dart';
import '../../spaces/gyms/presentation/gyms_screen.dart';
import '../../spaces/bookings/presentation/bookings_screen.dart';
import '../../spaces/wellness/presentation/wellness_screen.dart';
import '../../spaces/profile/presentation/profile_screen.dart';
import '../../spaces/notifications/notification_service.dart';

// ── Admin space ───────────────────────────────────────────────────────────────
import '../../core/admin/q_admin_shell.dart';
import '../../core/admin/screens/screen_admin_overview.dart';
import '../../core/admin/screens/screen_admin_content.dart';
import '../../core/admin/screens/screen_admin_brand.dart';
import '../../core/admin/screens/screen_admin_features.dart';
import '../../core/admin/screens/screen_admin_preview.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

/// Routes that never require Firebase Auth.
///
/// NOTE: '/admin' is deliberately NOT in this set as of v3.4.0.
/// Admin routes are protected — unauthenticated visitors are redirected to
/// /admin-login; authenticated non-admins are redirected to /home.
///
/// '/admin-login' IS public — it is the entry point for the admin flow,
/// and must be reachable without any prior session.
const _kPublicRoutes = {
  '/',
  '/landing',
  '/about',
  '/features',
  '/pricing',
  '/login',
  '/signup',
  '/admin-login', // Admin login entry point — public, but redirect-guarded
  '/dev',
};

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

      // ── Auth state ───────────────────────────────────────────────────────
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isLoggedIn    = authAsync.value != null;
      final isPublicRoute = _kPublicRoutes.contains(loc);

      // isAdminRoute: true for /admin itself and all /admin/* sub-routes.
      // This is computed BEFORE any login check so unauthenticated visitors
      // to /admin are correctly sent to /admin-login rather than /login.
      // Note: '/admin-login' does NOT match — it starts with '/admin-' not '/admin/'.
      final isAdminRoute  = loc == '/admin' || loc.startsWith('/admin/');

      // ── Not logged in ────────────────────────────────────────────────────
      if (!isLoggedIn) {
        if (isAdminRoute) return '/admin-login'; // Admin routes → admin gate
        if (isPublicRoute) return null;           // Public routes → pass through
        return '/login';                          // Protected routes → user gate
      }

      // ── Logged in: wait for Firestore user document ─────────────────────
      final userAsync = ref.read(firestoreUserProvider);
      if (userAsync.isLoading) return null;

      final isAdmin   = userAsync.value?.isAdmin   == true;
      final isTrainer = userAsync.value?.isTrainer  == true;

      // ── Logged-in user on a public / landing route ───────────────────────
      // Send each role to its own home screen.
      // The /admin-login route is included here via isPublicRoute — an already-
      // authenticated admin who navigates to /admin-login gets sent straight to
      // /admin instead of seeing the login form again.
      if (isPublicRoute) {
        if (isAdmin)   return '/admin';
        if (isTrainer) return '/trainer-dashboard';
        return '/home';
      }

      // ── Admin routes: require 'admin' role ───────────────────────────────
      // If a non-admin reaches an admin route (e.g. by typing the URL directly),
      // redirect to /home — they are authenticated but lack the required role.
      // We do NOT send them to /admin-login because they already have a session;
      // sending them to login again would be confusing. /home is the safe landing.
      if (isAdminRoute && !isAdmin) return '/home';

      // ── Role enforcement for non-admin app routes ────────────────────────
      if (loc == '/trainer-dashboard' && !isTrainer) return '/home';
      if (loc == '/home' && isTrainer)               return '/trainer-dashboard';

      // All other cases — pass through.
      return null;
    },
    routes: [

      // ── ROOT ───────────────────────────────────────────────────────────────
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

      // Developer roadmap page (accessible from production landing footer)
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

      // Admin login — separate entry point from /login.
      // Visually distinct (shield badge, restricted access messaging).
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
      // /discover redirects to /trainers — FABs + deep links remain valid.
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
      //
      // All admin routes are PROTECTED (role == 'admin') — enforced in the
      // redirect block above. QAdminShell wraps each screen with the sidebar
      // navigation + publish toolbar.
      //
      // Defense-in-depth: the redirect guard is the primary protection.
      // QAdminShell itself can add a secondary role check in a future revision
      // (see q_admin_shell.dart) if additional hardening is desired.

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
          const Text(
            'Page not found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            state.uri.path,
            style: const TextStyle(color: Colors.white30, fontSize: 12),
          ),
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
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
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