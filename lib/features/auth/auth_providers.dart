// lib/features/auth/auth_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers for authentication.
//
// Providers exported:
//   authRepositoryProvider  — singleton AuthRepository instance
//   authStateProvider       — Stream<User?> from Firebase Auth
//   userRoleProvider        — AsyncValue<String> role for the current user
//
// Used by:
//   signup_screen.dart, login_screen.dart — ref.read(authRepositoryProvider)
//   router.dart (GoRouter redirect)       — ref.watch(authStateProvider)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/auth_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Singleton [AuthRepository].  Override in tests via ProviderContainer overrides.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth state stream ─────────────────────────────────────────────────────────

/// Exposes `FirebaseAuth.authStateChanges()` as a Riverpod [StreamProvider].
/// Yields `null` when signed out, `User` when signed in.
///
/// The GoRouter redirect guard watches this to redirect unauthenticated users
/// to `/login` and authenticated users away from auth screens.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── User role ─────────────────────────────────────────────────────────────────

/// Reads the `role` field from Firestore for the currently signed-in user.
/// Returns `'user'` by default (safe fallback).
///
/// Used by GoRouter to redirect trainers to `/trainer-dashboard`.
final userRoleProvider = FutureProvider<String>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return 'user'; // not signed in

  return ref.read(authRepositoryProvider).getUserRole(authState.uid);
});