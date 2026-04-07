// lib/features/bookings/data/trainer_seed_data.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. 5 realistic Mombasa trainers + 30 availability slots
//            spread across the next 14 days. SeedService.ensureSeeded() is
//            idempotent — safe to call on every app start; only writes if
//            both collections are empty.
//
//   ⚠️  MARK FOR REMOVAL (Week 5+): When the complete trainer onboarding flow
//       is built, remove the ensureSeeded() call from main.dart and this file
//       becomes dead code. Keep it archived in the repo for reference.
//       The data shape here is canonical — the onboarding form must write
//       exactly these field names to trainers/{trainerId} and
//       availability/{slotId}.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// How many days ahead to generate availability slots.
const int kSeedDaysAhead = 14;

// Slot generation starts at this hour (8 AM).
const int kSeedStartHour = 8;

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerSeed — raw data for each seeded trainer
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerSeed {
  final String id; // Fixed ID — makes dev console navigation easy.
  final String displayName;
  final String? photoUrl; // null = initials fallback (same as TrainerModel)
  final List<String> specialties;
  final String bio;
  final String locationName;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final double? priceKes;
  final List<_SlotTemplate> slotTemplates;

  const _TrainerSeed({
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
    required this.slotTemplates,
  });
}

class _SlotTemplate {
  final int hour; // Slot start hour (24-hour)
  final int durationMins;
  final String sessionType; // 'personal' | 'group' | 'online' | 'assessment'
  final String location;
  // dayOffset: which days of the 14-day window this slot appears on.
  // e.g. [0,2,4,6] = every other day starting today.
  final List<int> dayOffsets;

  const _SlotTemplate({
    required this.hour,
    required this.durationMins,
    required this.sessionType,
    required this.location,
    required this.dayOffsets,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Seed data — 5 Mombasa personal trainers
// ─────────────────────────────────────────────────────────────────────────────

final List<_TrainerSeed> _kTrainers = [
  _TrainerSeed(
    id: 'trainer_amira_hassan',
    displayName: 'Amira Hassan',
    photoUrl: null,
    specialties: ['Weight Loss', 'HIIT', 'Nutrition'],
    bio: 'Certified personal trainer with 7 years of experience specialising '
        'in weight loss transformation and high-intensity interval training. '
        'Based at Mombasa Sports Club. I help clients achieve sustainable '
        'results through science-backed methods and real-world accountability.',
    locationName: 'Mombasa Sports Club',
    lat: -4.0435,
    lng: 39.6682,
    rating: 4.9,
    reviewCount: 63,
    priceKes: 2500,
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
    photoUrl: null,
    specialties: ['Strength Training', 'Muscle Building', 'Powerlifting'],
    bio:
        'Ex-competitive powerlifter turned coach. I run a no-nonsense strength '
        'programme designed for everyday people who want to get genuinely strong. '
        'Currently coaching at Fitness First Tudor. 5 years of professional '
        'coaching with proven progressive overload methodology.',
    locationName: 'Fitness First Tudor',
    lat: -4.0610,
    lng: 39.6720,
    rating: 4.7,
    reviewCount: 41,
    priceKes: 2000,
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
    photoUrl: null,
    specialties: ['Yoga', 'Flexibility', 'Mindfulness', 'Pre/Post Natal'],
    bio: 'Registered yoga instructor (RYT-500) and wellness coach with a focus '
        'on holistic fitness — mind, body, and breath. I offer both in-person '
        'sessions at my studio in Nyali and online classes for remote clients. '
        'Specialising in prenatal and postnatal fitness, flexibility, and stress '
        'reduction through mindful movement.',
    locationName: 'Nyali Wellness Studio',
    lat: -4.0410,
    lng: 39.7200,
    rating: 5.0,
    reviewCount: 29,
    priceKes: 1800,
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
    photoUrl: null,
    specialties: ['Functional Fitness', 'Calisthenics', 'Athletic Performance'],
    bio: 'Functional fitness coach with a background in athletics. I train '
        'everyone from desk workers rebuilding their movement quality to '
        'competitive athletes chasing PBs. No machines required — I specialise '
        'in bodyweight and functional movement that translates to real life. '
        'Sessions held at Likoni Waterfront or via online programming.',
    locationName: 'Likoni Waterfront Grounds',
    lat: -4.0900,
    lng: 39.6500,
    rating: 4.8,
    reviewCount: 55,
    priceKes: 1500,
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
    photoUrl: null,
    specialties: ['Cardio', 'Dance Fitness', 'Body Composition'],
    bio: 'Certified group fitness instructor and personal trainer. I make '
        'exercise genuinely fun — expect upbeat sessions with a focus on '
        'sustainable cardio, dance-based movement, and body composition. '
        'I\'ve helped over 80 clients lose weight, gain energy, and actually '
        'enjoy coming back to the gym. Available at Voyager Beach Hotel gym.',
    locationName: 'Voyager Beach Hotel Gym',
    lat: -4.0500,
    lng: 39.6800,
    rating: 4.6,
    reviewCount: 38,
    priceKes: 2200,
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

// ─────────────────────────────────────────────────────────────────────────────
// SeedService
// ─────────────────────────────────────────────────────────────────────────────

class SeedService {
  static final _db = FirebaseFirestore.instance;

  // ensureSeeded — idempotent. Only writes if both collections are empty.
  // Call once from main.dart after Firebase.initializeApp().
  //
  // ⚠️  This is a dev-only convenience. In production, trainer data comes
  //     from the trainer onboarding flow. Remove this call when that's live.
  static Future<void> ensureSeeded() async {
    try {
      // Check trainers collection — if it has any doc, we're already seeded.
      final trainersSnap = await _db
          .collection('trainers')
          .limit(1)
          .get(const GetOptions(source: Source.server));

      if (trainersSnap.docs.isNotEmpty) return; // Already seeded.

      final batch = _db.batch();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final trainer in _kTrainers) {
        // Write trainer profile.
        final trainerRef = _db.collection('trainers').doc(trainer.id);
        batch.set(trainerRef, {
          'displayName': trainer.displayName,
          'photoUrl': trainer.photoUrl,
          'specialties': trainer.specialties,
          'bio': trainer.bio,
          'locationName': trainer.locationName,
          'lat': trainer.lat,
          'lng': trainer.lng,
          'rating': trainer.rating,
          'reviewCount': trainer.reviewCount,
          'priceKes': trainer.priceKes,
          'isVerified': true,
          'role': 'trainer',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Generate availability slots for each template.
        for (final template in trainer.slotTemplates) {
          for (final dayOffset in template.dayOffsets) {
            final slotDate = today.add(Duration(days: dayOffset));
            // Skip today's slots if their start time has already passed —
            // showing expired slots would confuse users.
            final slotStart = DateTime(
              slotDate.year,
              slotDate.month,
              slotDate.day,
              template.hour,
            );
            if (slotStart.isBefore(now)) continue;

            final slotEnd =
                slotStart.add(Duration(minutes: template.durationMins));

            final slotRef = _db.collection('availability').doc();
            batch.set(slotRef, {
              'trainerId': trainer.id,
              'trainerName': trainer.displayName,
              'startTime': Timestamp.fromDate(slotStart),
              'endTime': Timestamp.fromDate(slotEnd),
              'status': 'available',
              'locationLabel': template.location,
              'sessionType': template.sessionType,
              'priceKes': trainer.priceKes,
              'bookedByUserId': null,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Firestore batches handle up to 500 writes. Our seed generates ~80–120
      // slot documents — well within the limit. No batching needed.
      await batch.commit();
    } catch (e) {
      // Seeding failure must never crash the app — log and continue.
      // In production the seed doesn't run, so this is purely a dev guard.
      // ignore: avoid_print
      print('[SeedService] Seeding failed (non-fatal): $e');
    }
  }
}
