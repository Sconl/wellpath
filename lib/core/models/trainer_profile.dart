// lib/core/models/trainer_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerProfile {
  final String id;
  final String displayName;
  final String? photoUrl;
  final List<String> specialties;
  final String bio;
  final String locationName;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final double? priceKes;
  final bool isVerified;
  final int? yearsExperience;
  final double? sessionRate;
  final int? clientCount;

  const TrainerProfile({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.specialties,
    required this.bio,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    this.priceKes,
    this.isVerified = false,
    this.yearsExperience,
    this.sessionRate,
    this.clientCount,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  String get priceDisplay => priceKes != null
      ? 'KES ${priceKes!.toStringAsFixed(0)}/session'
      : 'Contact trainer';

  factory TrainerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TrainerProfile(
      id: doc.id,
      displayName: data['displayName'] as String? ?? 'Trainer',
      photoUrl: data['photoUrl'] as String?,
      specialties: List<String>.from(data['specialties'] as List? ?? []),
      bio: data['bio'] as String? ?? '',
      locationName: data['locationName'] as String? ?? 'Location TBC',
      lat: (data['lat'] as num?)?.toDouble() ?? -4.0435,
      lng: (data['lng'] as num?)?.toDouble() ?? 39.6682,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      priceKes: (data['priceKes'] as num?)?.toDouble(),
      isVerified: data['isVerified'] as bool? ?? false,
      yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
      sessionRate: (data['sessionRate'] as num?)?.toDouble(),
      clientCount: (data['clientCount'] as num?)?.toInt(),
    );
  }
}
