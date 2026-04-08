// lib/core/models/trainer_profile.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.1.0 — Null-safety hardened + defensive parsing improvements:
//            - Strict defaults enforced for all non-nullable fields
//            - Safer List parsing for specialties
//            - Cleaner Firestore mapping
//            - No schema changes (clientCount intentionally NOT added)
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const String kTrainersCollection = 'trainers';
const int kMaxFeaturedTrainers = 20;

// ─────────────────────────────────────────────────────────────────────────────
// TrainerProfile
// ─────────────────────────────────────────────────────────────────────────────

class TrainerProfile {
  final String id;
  final String displayName;
  final String? photoUrl;
  final List<String> specialties;
  final String bio;
  final String locationName;
  final double rating;
  final int reviewCount;
  final double? priceKes;
  final bool isVerified;

  // Coordinates
  final double lat;
  final double lng;

  // Optional extended fields
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
    this.lat = -4.0435, // Mombasa fallback
    this.lng = 39.6682,
    this.yearsExperience,
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Computed Getters
  // ───────────────────────────────────────────────────────────────────────────

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  String get priceDisplay =>
      priceKes != null
          ? 'KES ${priceKes!.toStringAsFixed(0)}/session'
          : 'Contact trainer';

  /// Alias used in UI (DO NOT duplicate data)
  double? get sessionRate => priceKes;

  // ───────────────────────────────────────────────────────────────────────────
  // Firestore Mapping
  // ───────────────────────────────────────────────────────────────────────────

  factory TrainerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TrainerProfile(
      id: doc.id,

      displayName: data['displayName'] as String? ?? 'Trainer',

      photoUrl: data['photoUrl'] as String?,

      specialties: (data['specialties'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],

      bio: data['bio'] as String? ?? '',

      locationName: data['locationName'] as String? ?? 'Unknown',

      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,

      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,

      priceKes: (data['priceKes'] as num?)?.toDouble(),

      isVerified: data['isVerified'] as bool? ?? false,

      lat: (data['lat'] as num?)?.toDouble() ?? -4.0435,

      lng: (data['lng'] as num?)?.toDouble() ?? 39.6682,

      yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'specialties': specialties,
      'bio': bio,
      'locationName': locationName,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceKes': priceKes,
      'isVerified': isVerified,
      'lat': lat,
      'lng': lng,
      'yearsExperience': yearsExperience,
    };
  }
}