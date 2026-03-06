// lib/core/router/app_router.dart
// Revised router: fix GoRouterState API usage and simplify role logic for now.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../landing_page.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';

/// A small ChangeNotifier that listens to a stream and notifies GoRouter
/// when the stream emits. Used to refresh redirects on auth changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Provider exposing a configured GoRouter instance.
///
/// NOTE: This simplified version intentionally does *not* attempt to read a
/// Firestore-backed `firestoreUserProvider` to decide trainer vs user routing,
/// because the provider name/location may differ between projects and was the
/// source of the compile error. If you want role-based redirects, see the
/// TODO below and we can re-add provider reads once you confirm the provider
/// symbol and shape.
final routerProvider = Provider<GoRouter>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();
  final refreshListenable = GoRouterRefreshStream(authStream);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    routes: <GoRoute>[
      GoRoute(path: '/', builder: (context, state) => const LandingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/home', builder: (context, state) => const _HomePlaceholder()),
      GoRoute(path: '/trainer-dashboard', builder: (context, state) => const _TrainerPlaceholder()),
    ],

    // Redirect logic: keep it simple and reliable.
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.uri.path; // use `uri.path` for compatibility across go_router versions

      final firebaseUser = FirebaseAuth.instance.currentUser;

      final isAuthRoute = location == '/' || location == '/login' || location == '/signup';

      // Unauthenticated users: allow landing/login/signup; otherwise force /login.
      if (firebaseUser == null) {
        if (isAuthRoute) return null;
        return '/login';
      }

      // Authenticated users: prevent them from visiting login/signup by redirecting to /home.
      if (location == '/login' || location == '/signup' || location == '/') {
        return '/home';
      }

      // No redirect by default.
      return null;
    },
  );
});

/// Placeholder home screen — replace with your real HomeScreen widget.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('User Home (replace with real HomeScreen)')),
    );
  }
}

/// Placeholder trainer dashboard — replace with your real TrainerDashboard.
class _TrainerPlaceholder extends StatelessWidget {
  const _TrainerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainer Dashboard')),
      body: const Center(child: Text('Trainer Dashboard (replace with real screen)')),
    );
  }
}

// TODO: If you want role-based routing based on a Firestore user document,
// reintroduce a provider read in the redirect function. Example approach:
// 1) import the provider file (remove the `show` restriction that caused errors)
// 2) inside redirect(), use:
//    final container = ProviderScope.containerOf(context);
//    final asyncUser = container.read(firestoreUserProvider);
//    // extract role from asyncUser when available and act accordingly.
// I'll help add this once you confirm the exact provider symbol and its return type.
