// lib/features/bookings/data/trainer_seed_data.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. 5 Mombasa trainers + ~80 availability slots.
//   v2.0.0 — Added lat / lng / yearsExperience fields to match canonical
//            TrainerProfile model (lib/core/models/trainer_profile.dart).
//            All fields now written to Firestore so TrainerProfile.fromFirestore
//            reads complete documents with no missing fields.
//
//   ⚠️  MARK FOR REMOVAL (Week 5+): When trainer onboarding is live, remove
//       SeedService.ensureSeeded() from main.dart. Keep file as archive.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class _TrainerSeed {
  final String id;
  final String displayName;
  final List<String> specialties;
  final String bio;
  final String locationName;
  final double rating;
  final int reviewCount;
  final double? priceKes;
  final double lat;
  final double lng;
  final int yearsExperience;
  final List<_SlotTemplate> slotTemplates;

  const _TrainerSeed({
    required this.id,
    required this.displayName,
    required this.specialties,
    required this.bio,
    required this.locationName,
    required this.rating,
    required this.reviewCount,
    this.priceKes,
    required this.lat,
    required this.lng,
    required this.yearsExperience,
    required this.slotTemplates,
  });
}

class _SlotTemplate {
  final int hour;
  final int durationMins;
  final String sessionType;
  final String location;
  final List<int> dayOffsets;
  const _SlotTemplate({
    required this.hour,
    required this.durationMins,
    required this.sessionType,
    required this.location,
    required this.dayOffsets,
  });
}

final List<_TrainerSeed> _kTrainers = [
  _TrainerSeed(
    id: 'trainer_amira_hassan',
    displayName: 'Amira Hassan',
    specialties: ['Weight Loss', 'HIIT', 'Nutrition'],
    bio: 'Certified personal trainer with 7 years of experience specialising '
        'in weight loss transformation and HIIT. Based at Mombasa Sports Club. '
        'I help clients achieve sustainable results through science-backed methods.',
    locationName: 'Mombasa Sports Club',
    rating: 4.9,
    reviewCount: 63,
    priceKes: 2500,
    lat: -4.0570,
    lng: 39.6644,
    yearsExperience: 7,
    slotTemplates: [
      _SlotTemplate(
          hour: 6,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Mombasa Sports Club',
          dayOffsets: [0, 1, 2, 3, 4, 7, 8, 9, 10, 11]),
      _SlotTemplate(
          hour: 9,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Mombasa Sports Club',
          dayOffsets: [1, 3, 5, 8, 10, 12]),
      _SlotTemplate(
          hour: 17,
          durationMins: 60,
          sessionType: 'group',
          location: 'Mombasa Sports Club',
          dayOffsets: [2, 4, 6, 9, 11, 13]),
    ],
  ),
  _TrainerSeed(
    id: 'trainer_brian_mwangi',
    displayName: 'Brian Mwangi',
    specialties: ['Strength Training', 'Muscle Building', 'Powerlifting'],
    bio: 'Ex-competitive powerlifter turned coach. 5 years of professional '
        'coaching with proven progressive overload methodology at Fitness First Tudor.',
    locationName: 'Fitness First Tudor',
    rating: 4.7,
    reviewCount: 41,
    priceKes: 2000,
    lat: -4.0486,
    lng: 39.6745,
    yearsExperience: 5,
    slotTemplates: [
      _SlotTemplate(
          hour: 7,
          durationMins: 90,
          sessionType: 'personal',
          location: 'Fitness First Tudor',
          dayOffsets: [0, 2, 4, 6, 8, 10, 12]),
      _SlotTemplate(
          hour: 12,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Fitness First Tudor',
          dayOffsets: [1, 3, 5, 7, 9, 11, 13]),
      _SlotTemplate(
          hour: 16,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Fitness First Tudor',
          dayOffsets: [0, 2, 4, 7, 9, 11]),
    ],
  ),
  _TrainerSeed(
    id: 'trainer_fatuma_omar',
    displayName: 'Fatuma Omar',
    specialties: ['Yoga', 'Flexibility', 'Mindfulness', 'Pre/Post Natal'],
    bio: 'Registered yoga instructor (RYT-500) and wellness coach. In-person '
        'sessions at my Nyali studio and online classes for remote clients. '
        'Specialising in prenatal fitness and mindful movement.',
    locationName: 'Nyali Wellness Studio',
    rating: 5.0,
    reviewCount: 29,
    priceKes: 1800,
    lat: -4.0151,
    lng: 39.7200,
    yearsExperience: 9,
    slotTemplates: [
      _SlotTemplate(
          hour: 7,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Nyali Wellness Studio',
          dayOffsets: [0, 1, 3, 5, 7, 8, 10, 12]),
      _SlotTemplate(
          hour: 10,
          durationMins: 60,
          sessionType: 'online',
          location: 'Online (Zoom)',
          dayOffsets: [0, 2, 4, 6, 9, 11, 13]),
      _SlotTemplate(
          hour: 18,
          durationMins: 60,
          sessionType: 'group',
          location: 'Nyali Wellness Studio',
          dayOffsets: [1, 3, 5, 8, 10, 12]),
    ],
  ),
  _TrainerSeed(
    id: 'trainer_kevin_ochieng',
    displayName: 'Kevin Ochieng',
    specialties: ['Functional Fitness', 'Calisthenics', 'Athletic Performance'],
    bio: 'Functional fitness coach with an athletics background. I train desk '
        'workers and competitive athletes alike. No machines — pure functional '
        'movement at Likoni Waterfront or online.',
    locationName: 'Likoni Waterfront Grounds',
    rating: 4.8,
    reviewCount: 55,
    priceKes: 1500,
    lat: -4.0810,
    lng: 39.6630,
    yearsExperience: 4,
    slotTemplates: [
      _SlotTemplate(
          hour: 6,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Likoni Waterfront Grounds',
          dayOffsets: [0, 1, 2, 3, 4, 5, 6]),
      _SlotTemplate(
          hour: 8,
          durationMins: 60,
          sessionType: 'group',
          location: 'Likoni Waterfront Grounds',
          dayOffsets: [7, 8, 9, 10, 11, 12, 13]),
      _SlotTemplate(
          hour: 16,
          durationMins: 60,
          sessionType: 'online',
          location: 'Online (Google Meet)',
          dayOffsets: [0, 2, 4, 6, 8, 10, 12]),
    ],
  ),
  _TrainerSeed(
    id: 'trainer_grace_wanjiru',
    displayName: 'Grace Wanjiru',
    specialties: ['Cardio', 'Dance Fitness', 'Body Composition'],
    bio: 'Certified group fitness instructor making exercise genuinely fun. '
        'Upbeat sessions focused on sustainable cardio and body composition. '
        'Over 80 clients transformed. Based at Voyager Beach Hotel.',
    locationName: 'Voyager Beach Hotel Gym',
    rating: 4.6,
    reviewCount: 38,
    priceKes: 2200,
    lat: -3.9888,
    lng: 39.7167,
    yearsExperience: 6,
    slotTemplates: [
      _SlotTemplate(
          hour: 8,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Voyager Beach Hotel Gym',
          dayOffsets: [0, 2, 4, 7, 9, 11]),
      _SlotTemplate(
          hour: 10,
          durationMins: 45,
          sessionType: 'group',
          location: 'Voyager Beach Hotel Gym',
          dayOffsets: [1, 3, 5, 8, 10, 12]),
      _SlotTemplate(
          hour: 17,
          durationMins: 60,
          sessionType: 'personal',
          location: 'Voyager Beach Hotel Gym',
          dayOffsets: [0, 1, 3, 5, 7, 9, 13]),
      _SlotTemplate(
          hour: 7,
          durationMins: 60,
          sessionType: 'assessment',
          location: 'Voyager Beach Hotel Gym',
          dayOffsets: [6, 13]),
    ],
  ),
];

class SeedService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> ensureSeeded() async {
    try {
      final batch = _db.batch();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final trainer in _kTrainers) {
        final tRef = _db.collection('trainers').doc(trainer.id);
        batch.set(tRef, {
          'displayName': trainer.displayName,
          'photoUrl': null,
          'specialties': trainer.specialties,
          'bio': trainer.bio,
          'locationName': trainer.locationName,
          'rating': trainer.rating,
          'reviewCount': trainer.reviewCount,
          'priceKes': trainer.priceKes,
          'isVerified': true,
          'role': 'trainer',
          'lat': trainer.lat,
          'lng': trainer.lng,
          'yearsExperience': trainer.yearsExperience,
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (final t in trainer.slotTemplates) {
          for (int d = 0; d < 30; d++) {
            final slotDate = today.add(Duration(days: d));
            final slotStart =
                DateTime(slotDate.year, slotDate.month, slotDate.day, t.hour);
            if (slotStart.isBefore(now)) continue;
            final slotEnd = slotStart.add(Duration(minutes: t.durationMins));
            final sRef = _db.collection('availability').doc();
            batch.set(sRef, {
              'trainerId': trainer.id,
              'trainerName': trainer.displayName,
              'startTime': Timestamp.fromDate(slotStart),
              'endTime': Timestamp.fromDate(slotEnd),
              'status': 'available',
              'locationLabel': t.location,
              'sessionType': t.sessionType,
              'priceKes': trainer.priceKes,
              'bookedByUserId': null,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      await batch.commit();
    } catch (e) {
      // ignore: avoid_print
      print('[SeedService] Non-fatal: $e');
    }
  }
}
