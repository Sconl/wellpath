// lib/core/router/app_router.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial simplified router (FirebaseAuth.instance.currentUser direct,
//            no role routing, placeholder screens only).
//   v1.1.0 — Full rewrite:
//            • Replaced FirebaseAuth.instance.currentUser with Riverpod providers
//              (authStateProvider + firestoreUserProvider) so the redirect is
//              driven by the same state the UI observes — no split-brain.
//            • GoRouterRefreshStream replaced with _RouterNotifier (ChangeNotifier
//              that watches both Riverpod providers) so role changes trigger a
//              redirect re-evaluation without touching FirebaseAuth directly.
//            • Role-based routing implemented: trainers go to /trainer-dashboard,
//              users go to /home. Enforced in both directions (cross-role bounce).
//            • All routes wired: /landing, /login, /signup, /home,
//              /trainer-dashboard, /profile, /bookings, /wellness, /trainer/:id.
//            • Real HomeScreen imported and wired.
//            • _PlaceholderScreen added for routes not yet built (Weeks 3–6).
//            • Redirect guard handles loading states — returns null while
//              async providers are still resolving (no flash-of-wrong-route).
// ─────────────────────────────────────────────────────────────────────────────
//
// REDIRECT DECISION TABLE:
//
//   Auth state     │ Destination    │ Result
//   ───────────────┼────────────────┼──────────────────────────────────────────
//   Loading        │ anywhere       │ null — wait for stream to emit
//   Signed out     │ public route   │ null — stay
//   Signed out     │ protected      │ /login
//   Signed in      │ public route   │ /home  (or /trainer-dashboard if trainer)
//   Signed in (U)  │ /trainer-dash  │ /home  (role enforcement)
//   Signed in (T)  │ /home          │ /trainer-dashboard  (role enforcement)
//   Signed in      │ other protected│ null — stay
//
// PUBLIC ROUTES (no auth required):
//   /  /landing  /login  /signup
//
// PROTECTED ROUTES (auth required):
//   /home  /trainer-dashboard  /profile  /bookings  /wellness  /trainer/:id

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../landing_page.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/auth/providers/auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// Routes that don't require authentication.
const _kPublicRoutes = {'/', '/landing', '/login', '/signup'};

// ─────────────────────────────────────────────────────────────────────────────
// _RouterNotifier
// ─────────────────────────────────────────────────────────────────────────────
//
// Bridges Riverpod's provider system with GoRouter's ChangeNotifier-based
// refreshListenable. When either authStateProvider or firestoreUserProvider
// emits a new value, GoRouter re-evaluates the redirect function.
//
// Why both providers?
//   authStateProvider  — catches sign-in / sign-out events
//   firestoreUserProvider — catches role changes (e.g. manual trainer promotion
//                           via Firebase Console or setUserRole Cloud Function)
//
// Why NOT GoRouterRefreshStream on Firebase's authStateChanges() directly?
//   That bypasses Riverpod entirely. The redirect would read Firebase state
//   while the UI reads Riverpod state, creating a split-brain where the two
//   can briefly disagree. Using the same providers eliminates that gap.

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue>(authStateProvider,     (_, __) => notifyListeners());
    ref.listen<AsyncValue>(firestoreUserProvider, (_, __) => notifyListeners());
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

    // ── Redirect guard ──────────────────────────────────────────────────────
    redirect: (context, state) {
      final loc = state.uri.path;

      // ── 1. Auth state not yet resolved ─────────────────────────────────────
      // authStateProvider is a StreamProvider — on the very first frame it is
      // in AsyncLoading. Return null to hold position; the _RouterNotifier will
      // call notifyListeners() as soon as the stream emits, and GoRouter will
      // re-run this redirect function then.
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;

      final isLoggedIn    = authAsync.value != null;
      final isPublicRoute = _kPublicRoutes.contains(loc);

      // ── 2. Signed out ───────────────────────────────────────────────────────
      if (!isLoggedIn) {
        // Already on a public route — no redirect needed.
        if (isPublicRoute) return null;
        // Attempting a protected route — bounce to login.
        return '/login';
      }

      // ── 3. Signed in — wait for Firestore user document if still loading ───
      // Without the role we can't make a correct role-based decision.
      // Hold position until firestoreUserProvider resolves.
      final userAsync = ref.read(firestoreUserProvider);
      if (userAsync.isLoading) return null;

      final user      = userAsync.value;
      final isTrainer = user?.isTrainer == true;

      // ── 4. Signed in — on a public/auth route → redirect away ──────────────
      if (isPublicRoute) {
        return isTrainer ? '/trainer-dashboard' : '/home';
      }

      // ── 5. Role enforcement — prevent wrong-role access ─────────────────────
      // A regular user who somehow lands on /trainer-dashboard goes to /home.
      if (loc == '/trainer-dashboard' && !isTrainer) return '/home';
      // A trainer who somehow lands on /home goes to /trainer-dashboard.
      if (loc == '/home' && isTrainer) return '/trainer-dashboard';

      // ── 6. All clear ────────────────────────────────────────────────────────
      return null;
    },

    // ── Routes ─────────────────────────────────────────────────────────────
    routes: [

      // ── Public ─────────────────────────────────────────────────────────────
      GoRoute(
        path:    '/',
        // Bare root redirects to /landing so the URL is always explicit.
        redirect: (_, __) => '/landing',
      ),
      GoRoute(
        path:    '/landing',
        name:    'landing',
        builder: (_, __) => const LandingPage(),
      ),
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

      // ── Protected — regular user ────────────────────────────────────────────
      GoRoute(
        path:    '/home',
        name:    'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path:    '/profile',
        name:    'profile',
        builder: (_, __) => const _PlaceholderScreen(
          title: 'Profile',
          icon:  Icons.person_outline,
          week:  'Week 2 — Day 7',
        ),
      ),
      GoRoute(
        path:    '/bookings',
        name:    'bookings',
        builder: (_, __) => const _PlaceholderScreen(
          title: 'My Bookings',
          icon:  Icons.calendar_today_outlined,
          week:  'Week 4',
        ),
      ),
      GoRoute(
        path:    '/wellness',
        name:    'wellness',
        builder: (_, __) => const _PlaceholderScreen(
          title: 'Track Wellness',
          icon:  Icons.favorite_outline,
          week:  'Week 5',
        ),
      ),

      // ── Protected — trainer ─────────────────────────────────────────────────
      GoRoute(
        path:    '/trainer-dashboard',
        name:    'trainerDashboard',
        builder: (_, __) => const HomeScreen(isTrainerView: true),
      ),

      // ── Trainer profile (public — browsable without login) ──────────────────
      GoRoute(
        path: '/trainer/:id',
        name: 'trainerProfile',
        builder: (_, state) => _PlaceholderScreen(
          title: 'Trainer Profile',
          icon:  Icons.person_search_outlined,
          week:  'Week 3',
          subtitle: state.pathParameters['id'],
        ),
      ),
    ],

    // ── Error page ──────────────────────────────────────────────────────────
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
// _PlaceholderScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Rendered for every route that hasn't been built yet.
// Shows a labelled card so you can tap through the full navigation graph
// and confirm routing is correct before each week's screens are written.
// Replace each one as its sprint week arrives.

class _PlaceholderScreen extends StatelessWidget {
  final String  title;
  final IconData icon;
  final String  week;
  final String? subtitle;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.week,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020E08),
      appBar: AppBar(
        backgroundColor:  Colors.transparent,
        elevation:        0,
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: const TextStyle(color: Colors.white30, fontSize: 13)),
            ],
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