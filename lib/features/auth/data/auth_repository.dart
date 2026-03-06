// lib/features/auth/data/auth_repository.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// AuthRepository — wraps Firebase Auth + Firestore user-document creation.
//
// Called by:
//   authRepositoryProvider  (auth_providers.dart)
//   signup_screen.dart      → signUp()
//   login_screen.dart       → signIn()
//
// Firestore document written on signup:
//   users/{uid} {
//     uid, email, displayName,
//     role: 'user',
//     createdAt,
//     preferences: { dailyReminderEnabled: false, reminderTime: '20:00' }
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth     _auth;
  final FirebaseFirestore _db;

  AuthRepository({
    FirebaseAuth?      auth,
    FirebaseFirestore?  db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db   = db   ?? FirebaseFirestore.instance;

  // ── Auth state stream ──────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Sign Up ────────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account, updates the display name, and writes
  /// the initial Firestore user document.
  ///
  /// Throws [FirebaseAuthException] on auth failures.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // 1. Create auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );

    final user = credential.user!;

    // 2. Update display name on the Auth object
    await user.updateDisplayName(displayName);

    // 3. Write users/{uid} to Firestore
    await _db.collection('users').doc(user.uid).set({
      'uid':         user.uid,
      'email':       email,
      'displayName': displayName,
      'role':        'user',
      'createdAt':   FieldValue.serverTimestamp(),
      'preferences': {
        'dailyReminderEnabled': false,
        'reminderTime':         '20:00',
      },
    });
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  /// Signs in with email and password.
  ///
  /// Throws [FirebaseAuthException] on failure.
  /// The GoRouter auth-redirect guard handles post-login navigation.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email:    email,
      password: password,
    );
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Fetch user role from Firestore ─────────────────────────────────────────

  /// Reads the `role` field from `users/{uid}`.
  /// Returns `'user'` if the document doesn't exist yet (safe default).
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'user';
    return (doc.data()?['role'] as String?) ?? 'user';
  }
}