// lib/features/auth/data/user_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Extracted from auth_providers.dart into its own file.
//            UserPreferences + UserModel are pure data objects with zero
//            Firebase or Riverpod dependencies — testable in isolation.
//   v1.1.0 — Admin role support added:
//            • `isAdmin` getter added to UserModel (role == 'admin').
//            • kDefaultRole remains 'user' — admin accounts are provisioned
//              manually; they never come from the signup flow.
//            • Role documentation updated to include 'admin' as valid value.
//            • No breaking changes — existing Firestore documents unaffected.
// ─────────────────────────────────────────────────────────────────────────────
//
// WHY SEPARATE FROM auth_repository.dart:
//   Models should have zero framework dependencies. This file can be unit-tested
//   without Firebase, without Riverpod, without a device.
//
// FIRESTORE DOCUMENT SHAPE  (users/{uid}):
//   uid:          string
//   email:        string
//   displayName:  string          ← Firestore is the source of truth, not Auth profile
//   role:         'user' | 'trainer' | 'admin'
//   photoUrl:     string?
//   createdAt:    Timestamp
//   updatedAt:    Timestamp
//   preferences: {
//     dailyReminderEnabled: bool    (default: false)
//     reminderTime:         string  (default: '20:00' EAT)
//   }
//
// ROLE HIERARCHY:
//   'user'    — standard app user. Default for all signup-created accounts.
//   'trainer' — personal trainer. Set via setUserRole Cloud Function.
//   'admin'   — platform administrator. Provisioned manually via Firebase Console
//               or setUserRole Cloud Function. Never created through public signup.
//               Admin accounts have access to the /admin portal and all admin
//               sub-routes. GoRouter enforces this via the isAdmin flag below.

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const String kDefaultRole            = 'user';
const bool   kDefaultReminderEnabled = false;
const String kDefaultReminderTime    = '20:00'; // EAT — East Africa Time, UTC+3

// ─────────────────────────────────────────────────────────────────────────────
// UserPreferences
// ─────────────────────────────────────────────────────────────────────────────

class UserPreferences {
  final bool   dailyReminderEnabled;
  final String reminderTime; // 'HH:mm' 24-hour format

  const UserPreferences({
    required this.dailyReminderEnabled,
    required this.reminderTime,
  });

  /// Defaults written to Firestore on every new signup.
  factory UserPreferences.defaults() => const UserPreferences(
        dailyReminderEnabled: kDefaultReminderEnabled,
        reminderTime:         kDefaultReminderTime,
      );

  factory UserPreferences.fromMap(Map<String, dynamic> map) => UserPreferences(
        dailyReminderEnabled: map['dailyReminderEnabled'] as bool?   ?? kDefaultReminderEnabled,
        reminderTime:         map['reminderTime']         as String? ?? kDefaultReminderTime,
      );

  Map<String, dynamic> toMap() => {
        'dailyReminderEnabled': dailyReminderEnabled,
        'reminderTime':         reminderTime,
      };

  UserPreferences copyWith({
    bool?   dailyReminderEnabled,
    String? reminderTime,
  }) =>
      UserPreferences(
        dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
        reminderTime:         reminderTime         ?? this.reminderTime,
      );

  @override
  String toString() =>
      'UserPreferences(reminder=$dailyReminderEnabled @ $reminderTime)';
}

// ─────────────────────────────────────────────────────────────────────────────
// UserModel
// ─────────────────────────────────────────────────────────────────────────────

class UserModel {
  final String          uid;
  final String          email;
  final String          displayName;
  final String          role;       // 'user' | 'trainer' | 'admin'
  final String?         photoUrl;
  final DateTime?       createdAt;
  final DateTime?       updatedAt;
  final UserPreferences preferences;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    required this.preferences,
  });

  // ── Role getters ───────────────────────────────────────────────────────────
  //
  // isAdmin:   platform administrator — has access to /admin portal.
  //            These accounts are provisioned manually and never come from
  //            the public signup flow.
  //
  // isTrainer: personal trainer — has access to /trainer-dashboard.
  //            Set via setUserRole Cloud Function.
  //
  // isUser:    standard app user. Default for all signup-created accounts.
  //            Note: isUser is true for any account that is NOT a trainer or admin,
  //            matching the intent of the 'user' role rather than being exclusive
  //            to role == 'user'. Adjust if trainer/admin hybrid accounts are needed.

  bool get isAdmin   => role == 'admin';
  bool get isTrainer => role == 'trainer';
  bool get isUser    => role == 'user';

  /// Deserialises a Firestore document snapshot into a UserModel.
  /// All fields are null-safe — a partially-written document will not crash.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid:         data['uid']         as String? ?? doc.id,
      email:       data['email']       as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role:        data['role']        as String? ?? kDefaultRole,
      photoUrl:    data['photoUrl']    as String?,
      createdAt:   (data['createdAt']  as Timestamp?)?.toDate(),
      updatedAt:   (data['updatedAt']  as Timestamp?)?.toDate(),
      preferences: data['preferences'] != null
          ? UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>)
          : UserPreferences.defaults(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid':         uid,
        'email':       email,
        'displayName': displayName,
        'role':        role,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt':   FieldValue.serverTimestamp(),
        'preferences': preferences.toMap(),
      };

  UserModel copyWith({
    String?          displayName,
    String?          photoUrl,
    UserPreferences? preferences,
  }) =>
      UserModel(
        uid:         uid,
        email:       email,
        displayName: displayName ?? this.displayName,
        role:        role,
        photoUrl:    photoUrl    ?? this.photoUrl,
        createdAt:   createdAt,
        updatedAt:   updatedAt,
        preferences: preferences ?? this.preferences,
      );

  @override
  String toString() =>
      'UserModel(uid=$uid, email=$email, role=$role)';
}