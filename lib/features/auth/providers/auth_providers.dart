// lib/features/auth/providers/auth_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — All four Riverpod providers. AuthRepository, UserModel, and
//            UserPreferences now live in their own files under data/.
//            This file is providers only — zero class definitions.
// ─────────────────────────────────────────────────────────────────────────────
//
// PROVIDER SUMMARY:
//
//   authRepositoryProvider   — single AuthRepository instance (injectable for tests)
//   authStateProvider        — Stream<User?> from Firebase Auth
//                              GoRouter reads this: is the user logged in?
//   firestoreUserProvider    — Stream<UserModel?> from Firestore
//                              GoRouter reads this: what is the user's role?
//                              ProfileScreen reads this: displayName, photoUrl, prefs
//   currentUserModelProvider — synchronous UserModel? .value accessor
//                              Use inside auth-guarded screens to skip AsyncValue wrapping
//
// WHO IMPORTS WHAT:
//   app_router.dart          → authStateProvider, firestoreUserProvider
//   login_screen.dart        → authRepositoryProvider
//   signup_screen.dart       → authRepositoryProvider
//   profile_screen.dart      → firestoreUserProvider, authRepositoryProvider
//   any auth-gated screen    → currentUserModelProvider

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/user_model.dart';

export '../data/auth_repository.dart';
export '../data/user_model.dart';

// ── authRepositoryProvider ───────────────────────────────────────────────────
//
// Single instance. Override in tests via ProviderContainer(overrides: [...]).

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── authStateProvider ────────────────────────────────────────────────────────
//
// Thin wrapper around Firebase's authStateChanges() stream.
// Emits null when signed out, non-null User when signed in.
// This is the only signal GoRouter needs for "is logged in?" decisions.
// It carries NO role or profile data — just identity.
//
// authChanges() (vs idTokenChanges()) re-emits on custom-claim refresh,
// which matters when setUserRole Cloud Function forces a token refresh
// to promote a user to trainer. Token refresh will re-trigger GoRouter
// redirect and send the trainer to /trainer-dashboard automatically.

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── firestoreUserProvider ────────────────────────────────────────────────────
//
// Streams the full UserModel from Firestore for the currently signed-in user.
//
// Chain design: this provider watches authStateProvider. When auth state
// emits null (sign-out), this immediately returns Stream.value(null) without
// opening a Firestore listener. This is the safeguard that prevents stale
// UserModel data from leaking into post-logout screens.
//
// Sequence on sign-out:
//   1. signOut() called
//   2. authStateProvider emits null
//   3. firestoreUserProvider rebuilds → uid is null → emits Stream.value(null)
//   4. GoRouter redirect fires → user sent to /landing
//   5. No stale UserModel can reach any screen

final firestoreUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  final uid       = authState?.uid;

  if (uid == null) return Stream.value(null);

  return ref.watch(authRepositoryProvider).userStream(uid);
});

// ── currentUserModelProvider ─────────────────────────────────────────────────
//
// Synchronous .value accessor for the current UserModel.
// Use this inside screens that are behind the GoRouter auth guard,
// where you know the user is authenticated and don't need AsyncValue wrapping.
//
// Returns null during the brief window while the Firestore stream is loading.
// For screens that must show a loading state, use firestoreUserProvider directly.

final currentUserModelProvider = Provider<UserModel?>((ref) {
  return ref.watch(firestoreUserProvider).value;
});