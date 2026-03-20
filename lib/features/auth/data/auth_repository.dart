// lib/features/auth/data/auth_repository.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial release. AuthRepository + Firestore user document creation.
//   v1.1.0 — Bug 1 fixed: updateDisplayName wrapped in try-catch with user.reload().
//            Bug was: Flutter Web throws immediately after createUserWithEmailAndPassword
//            because the User object isn't fully initialized on the web platform.
//            Fix: reload() first, then try updateDisplayName. Failure is non-fatal
//            because Firestore (step 3) is the source of truth for displayName.
//   v1.2.0 — Extracted UserModel/UserPreferences to user_model.dart.
//            This file now has zero data-class definitions — pure operations only.
// ─────────────────────────────────────────────────────────────────────────────
//
// ARCHITECTURE RULE:
//   Nothing outside this file (and auth_providers.dart) should import
//   FirebaseAuth or call Firestore for auth operations.
//   Screens talk to AuthRepository. AuthRepository talks to Firebase.
//
// INJECTABLE FOR TESTS:
//   Pass fake FirebaseAuth / FirebaseFirestore via constructor.
//   ProviderContainer overrides handle this in widget tests.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const String kUsersCollection = 'users';

// ─────────────────────────────────────────────────────────────────────────────
// AuthRepository
// ─────────────────────────────────────────────────────────────────────────────

class AuthRepository {
  final FirebaseAuth      _auth;
  final FirebaseFirestore _db;

  AuthRepository({
    FirebaseAuth?      auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db   = db   ?? FirebaseFirestore.instance;

  // ── Auth state ─────────────────────────────────────────────────────────────

  /// Raw Firebase Auth stream. Emits null on sign-out, User on sign-in.
  /// GoRouter watches this via authStateProvider.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Synchronous current user. Null when signed out.
  User? get currentUser => _auth.currentUser;

  // ── Sign Up ────────────────────────────────────────────────────────────────
  //
  // Three steps. All must succeed for the account to be usable.
  //
  //   Step 1 — Firebase Auth account creation (required)
  //   Step 2 — Auth profile displayName update (non-fatal if it fails)
  //             Flutter Web timing bug: User object isn't fully ready after
  //             createUserWithEmailAndPassword. Fix: reload() first, then
  //             wrap in try-catch. The Firestore document (step 3) is the
  //             authoritative displayName source — this is a convenience copy.
  //   Step 3 — Firestore users/{uid} document creation (required)
  //
  // Common step-3 failure causes on first run:
  //   • Firestore not enabled in Firebase Console
  //   • Security rules blocking the write (test mode has 30-day expiry)
  //   • cloud_firestore not in pubspec.yaml
  //   • firebase_core not initialised before runApp()

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    debugPrint('[AuthRepository] signUp: step 1 — creating Auth account for $email');

    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );
    final user = credential.user!;

    debugPrint('[AuthRepository] signUp: step 1 done — uid ${user.uid}');

    // Step 2 — non-fatal. Flutter Web: User object isn't ready immediately.
    // reload() forces a fresh token fetch which initialises the User fully.
    try {
      await user.reload();
      // Re-fetch the user reference after reload — the original reference
      // may be stale on web after a token refresh.
      final freshUser = _auth.currentUser!;
      await freshUser.updateDisplayName(displayName);
      debugPrint('[AuthRepository] signUp: step 2 done — Auth displayName set');
    } catch (e) {
      // Non-fatal — Firestore document (step 3) is the source of truth.
      debugPrint('[AuthRepository] signUp: step 2 SKIPPED (non-fatal): $e');
    }

    // Step 3 — required. This is the authoritative user document.
    debugPrint('[AuthRepository] signUp: step 3 — writing Firestore document users/${user.uid}');
    await _db.collection(kUsersCollection).doc(user.uid).set({
      'uid':         user.uid,
      'email':       email,
      'displayName': displayName,
      'role':        kDefaultRole,
      'photoUrl':    null,
      'createdAt':   FieldValue.serverTimestamp(),
      'updatedAt':   FieldValue.serverTimestamp(),
      'preferences': UserPreferences.defaults().toMap(),
    });
    debugPrint('[AuthRepository] signUp: step 3 done — signup complete ✓');

    return credential;
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  //
  // Returns UserCredential. Navigation is handled by GoRouter's authStateProvider
  // redirect guard — no explicit context.go() in the calling screen.

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email:    email,
      password: password,
    );
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  //
  // Clears local Auth state. authStateProvider emits null → GoRouter
  // redirect guard sends user to /landing.

  Future<void> signOut() => _auth.signOut();

  // ── Password Reset ─────────────────────────────────────────────────────────
  //
  // Exposed here so screens never need to import FirebaseAuth directly.

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Update Display Name ────────────────────────────────────────────────────
  //
  // Writes to both Auth profile and Firestore in parallel.
  // Used by ProfileScreen edit form (Week 2 Day 7).

  Future<void> updateDisplayName(String displayName) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await Future.wait([
      _auth.currentUser!.updateDisplayName(displayName),
      _db.collection(kUsersCollection).doc(uid).update({
        'displayName': displayName,
        'updatedAt':   FieldValue.serverTimestamp(),
      }),
    ]);
  }

  // ── Update Photo URL ───────────────────────────────────────────────────────
  //
  // Called after a successful Firebase Storage upload.
  // The upload itself lives in StorageRepository (Week 7).

  Future<void> updatePhotoUrl(String photoUrl) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await Future.wait([
      _auth.currentUser!.updatePhotoURL(photoUrl),
      _db.collection(kUsersCollection).doc(uid).update({
        'photoUrl':  photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  // ── Update Preferences ─────────────────────────────────────────────────────
  //
  // Granular update of the preferences sub-map only.
  // Called by NotificationSettingsScreen (Week 6).

  Future<void> updatePreferences(UserPreferences preferences) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection(kUsersCollection).doc(uid).update({
      'preferences': preferences.toMap(),
      'updatedAt':   FieldValue.serverTimestamp(),
    });
  }

  // ── Firestore User Stream ──────────────────────────────────────────────────
  //
  // Real-time stream of the UserModel for a given UID.
  // Consumed by firestoreUserProvider in auth_providers.dart.
  // Returns null if the document doesn't exist yet.

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(kUsersCollection)
        .doc(uid)
        .withConverter<UserModel?>(
          fromFirestore: (snap, _) =>
              snap.exists ? UserModel.fromFirestore(snap) : null,
          toFirestore:   (model, _) => model?.toMap() ?? {},
        )
        .snapshots()
        .map((snap) => snap.data());
  }
}