// lib/core/models/trainer_profile.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Canonical TrainerProfile model. Moved from booking_providers.dart
//            into core/models so every feature (home map, discover list,
//            trainer profile, booking sheet) shares a single type.
//
//   FIELDS:
//   - lat / lng          — for AppMapPin placement on home & discover maps.
//   - yearsExperience    — shown in stats strip on profile screen.
//   - sessionRate        — getter alias for priceKes; used by profile stats strip.
//   - isVerified         — shows the blue verified badge on profile hero.
//
//   FIRESTORE SHAPE:  trainers/{trainerId}
//   {
//     displayName, photoUrl, specialties[], bio, locationName,
//     rating, reviewCount, priceKes, isVerified, lat, lng,
//     yearsExperience, role, createdAt
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const String kTrainersCollection = 'trainers';
const int    kMaxFeaturedTrainers = 20;

// ─────────────────────────────────────────────────────────────────────────────
// TrainerProfile
// ─────────────────────────────────────────────────────────────────────────────

class TrainerProfile {
  final String       id;
  final String       displayName;
  final String?      photoUrl;
  final List<String> specialties;
  final String       bio;
  final String       locationName;
  final double       rating;
  final int          reviewCount;
  final double?      priceKes;
  final bool         isVerified;

  // Coordinates for map pins — written by seed data and trainer onboarding.
  // Fallback to Mombasa CBD (kFallbackLat / kFallbackLng) if absent.
  final double lat;
  final double lng;

  // Optional extended fields — populated by trainer onboarding (Week 5+).
  final int? yearsExperience;

  const TrainerProfile({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.specialties,
    required this.bio,
    required this.locationName,
    required this.rating,
    required this.reviewCount,
    this.priceKes,
    this.isVerified = false,
    this.lat = -4.0435, // Mombasa CBD fallback
    this.lng = 39.6682,
    this.yearsExperience,
  });

  // ── Computed getters ───────────────────────────────────────────────────────

  /// Two-character initials for the avatar fallback.
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  /// Formatted price string for card + profile hero display.
  String get priceDisplay =>
      priceKes != null ? 'KES ${priceKes!.toStringAsFixed(0)}/session' : 'Contact trainer';

  /// sessionRate is the profile-screen name for the same value as priceKes.
  /// Alias keeps the stats strip readable without duplication.
  double? get sessionRate => priceKes;

  // ── Firestore ──────────────────────────────────────────────────────────────

  factory TrainerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TrainerProfile(
      id:               doc.id,
      displayName:      data['displayName']    as String?  ?? 'Trainer',
      photoUrl:         data['photoUrl']       as String?,
      specialties:      List<String>.from(data['specialties'] as List? ?? []),
      bio:              data['bio']            as String?  ?? '',
      locationName:     data['locationName']   as String?  ?? 'Mombasa',
      rating:           (data['rating']        as num?)?.toDouble() ?? 0.0,
      reviewCount:      (data['reviewCount']   as num?)?.toInt()    ?? 0,
      priceKes:         (data['priceKes']      as num?)?.toDouble(),
      isVerified:       data['isVerified']     as bool?    ?? false,
      lat:              (data['lat']           as num?)?.toDouble() ?? -4.0435,
      lng:              (data['lng']           as num?)?.toDouble() ?? 39.6682,
      yearsExperience:  (data['yearsExperience'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'displayName':     displayName,
    'photoUrl':        photoUrl,
    'specialties':     specialties,
    'bio':             bio,
    'locationName':    locationName,
    'rating':          rating,
    'reviewCount':     reviewCount,
    'priceKes':        priceKes,
    'isVerified':      isVerified,
    'lat':             lat,
    'lng':             lng,
    'yearsExperience': yearsExperience,
  };
}