// lib/features/home/data/trainer_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Mirrors trainers/{trainerId} Firestore schema from
//            the Feature 1 data model spec. Pure data, no UI/Firebase imports
//            beyond cloud_firestore for the Timestamp conversion.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const kTrainersCollection = 'trainers';

// How many trainers to surface on the home screen discovery strip.
// Keep low — this is a real-time listener; fewer docs = lower read cost.
const kMaxFeaturedTrainers = 10;

// ─────────────────────────────────────────────────────────────────────────────
// TrainerModel
// ─────────────────────────────────────────────────────────────────────────────

class TrainerModel {
  final String       id;
  final String       userId;        // links back to users/{uid}
  final String       displayName;
  final List<String> specialties;
  final String       bio;
  final String?      photoUrl;
  final GeoPoint?    location;      // Mombasa pilot — lat/lng for future proximity search
  final DateTime?    createdAt;

  const TrainerModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.specialties,
    required this.bio,
    this.photoUrl,
    this.location,
    this.createdAt,
  });

  factory TrainerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TrainerModel(
      id:          doc.id,
      userId:      data['userId']      as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      specialties: List<String>.from(data['specialties'] as List? ?? []),
      bio:         data['bio']         as String? ?? '',
      photoUrl:    data['photoUrl']    as String?,
      location:    data['location']    as GeoPoint?,
      createdAt:   (data['createdAt']  as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId':      userId,
    'displayName': displayName,
    'specialties': specialties,
    'bio':         bio,
    'photoUrl':    photoUrl,
    'location':    location,
    'createdAt':   createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };

  // Convenience for building avatar initials without an extra import
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}