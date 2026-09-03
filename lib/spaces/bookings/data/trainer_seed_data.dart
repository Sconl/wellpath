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
//   v2.1.0 — CRITICAL FIX: availability slot IDs are now deterministic
//            (trainerId + date offset + hour), making every batch.set()
//            idempotent. Calling ensureSeeded() multiple times no longer
//            creates duplicate slots — it overwrites the same documents.
//            Also expanded trainer bios, added certifications field, richer
//            slot variety (more hours, mix of session types per trainer).
//
//   ⚠️  MARK FOR REMOVAL (Week 5+): When trainer onboarding is live, remove
//       SeedService.ensureSeeded() from main.dart. Keep file as archive.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class _TrainerSeed {
  final String id;
  final String displayName;
  final List<String> specialties;
  final List<String> certifications;
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
    required this.certifications,
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
  // dayOffsets: which days from today this slot recurs on.
  // Keep this list SHORT and NON-OVERLAPPING to avoid duplicate hours
  // on the same date. Each (dayOffset, hour) pair maps to exactly one
  // deterministic Firestore document ID.
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
  // ── Amira Hassan ─────────────────────────────────────────────────────────
  _TrainerSeed(
    id: 'trainer_amira_hassan',
    displayName: 'Amira Hassan',
    specialties: ['Weight Loss', 'HIIT', 'Nutrition Coaching', 'Cardio'],
    certifications: ['ACE-CPT', 'Precision Nutrition L1', 'HIIT Specialist'],
    bio:
        'I\'ve spent 7 years helping people in Mombasa transform their bodies and '
        'relationship with fitness. My approach blends high-intensity interval '
        'training with evidence-based nutrition — no fad diets, no shortcuts. '
        'Whether you\'re starting from zero or breaking a plateau, I\'ll build a '
        'programme that actually fits your life. Based at Mombasa Sports Club.',
    locationName: 'Mombasa Sports Club',
    rating: 4.9,
    reviewCount: 63,
    priceKes: 2500,
    lat: -4.0570,
    lng: 39.6644,
    yearsExperience: 7,
    slotTemplates: [
      // Early morning personal sessions — Mon, Wed, Fri, Mon+1, Wed+1, Fri+1
      _SlotTemplate(
        hour: 6,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Mombasa Sports Club',
        dayOffsets: [0, 2, 4, 7, 9, 11, 14, 16, 18],
      ),
      // Mid-morning personal — Tue, Thu, Sat
      _SlotTemplate(
        hour: 9,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Mombasa Sports Club',
        dayOffsets: [1, 3, 5, 8, 10, 12, 15, 17, 19],
      ),
      // Evening group HIIT — Tue, Thu, Sat
      _SlotTemplate(
        hour: 17,
        durationMins: 60,
        sessionType: 'group',
        location: 'Mombasa Sports Club',
        dayOffsets: [2, 4, 6, 9, 11, 13, 16, 18, 20],
      ),
    ],
  ),

  // ── Brian Mwangi ─────────────────────────────────────────────────────────
  _TrainerSeed(
    id: 'trainer_brian_mwangi',
    displayName: 'Brian Mwangi',
    specialties: [
      'Strength Training',
      'Powerlifting',
      'Muscle Building',
      'Sport Performance'
    ],
    certifications: [
      'NSCA-CSCS',
      'IPF Level 2 Coach',
      'FMS Level 1'
    ],
    bio:
        'Ex-competitive powerlifter, current coach. I spent five years on the '
        'national circuit before a knee injury redirected my focus to helping '
        'others build the strength I worked so hard to develop myself. My '
        'progressive overload methodology has helped 40+ clients hit personal '
        'records they didn\'t think were possible. Sessions at Fitness First Tudor '
        '— proper equipment, no excuses.',
    locationName: 'Fitness First Tudor',
    rating: 4.7,
    reviewCount: 41,
    priceKes: 2000,
    lat: -4.0486,
    lng: 39.6745,
    yearsExperience: 5,
    slotTemplates: [
      // Morning strength sessions — Mon, Wed, Fri
      _SlotTemplate(
        hour: 7,
        durationMins: 90,
        sessionType: 'personal',
        location: 'Fitness First Tudor',
        dayOffsets: [0, 2, 4, 7, 9, 11, 14, 16, 18],
      ),
      // Lunchtime sessions — Tue, Thu
      _SlotTemplate(
        hour: 12,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Fitness First Tudor',
        dayOffsets: [1, 3, 8, 10, 15, 17],
      ),
      // Afternoon sessions — Mon, Wed, Sat
      _SlotTemplate(
        hour: 16,
        durationMins: 75,
        sessionType: 'personal',
        location: 'Fitness First Tudor',
        dayOffsets: [0, 2, 5, 7, 9, 12, 14, 16, 19],
      ),
    ],
  ),

  // ── Fatuma Omar ──────────────────────────────────────────────────────────
  _TrainerSeed(
    id: 'trainer_fatuma_omar',
    displayName: 'Fatuma Omar',
    specialties: [
      'Yoga',
      'Flexibility',
      'Mindfulness',
      'Pre/Post Natal',
      'Breathwork'
    ],
    certifications: ['RYT-500', 'Pre/Post Natal Fitness', 'Mindfulness-Based Stress Reduction'],
    bio:
        'Movement is medicine — that\'s the philosophy behind everything I do. '
        'As a 500-hour certified yoga instructor and wellness coach, I work with '
        'clients across the full spectrum: beginners finding their breath, '
        'athletes recovering from injury, and expectant mothers navigating '
        'pregnancy with strength and calm. My Nyali studio is a sanctuary. '
        'Online classes are available for those who prefer the flexibility of home.',
    locationName: 'Nyali Wellness Studio',
    rating: 5.0,
    reviewCount: 29,
    priceKes: 1800,
    lat: -4.0151,
    lng: 39.7200,
    yearsExperience: 9,
    slotTemplates: [
      // Morning in-person yoga — Mon, Tue, Thu, Sat
      _SlotTemplate(
        hour: 7,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Nyali Wellness Studio',
        dayOffsets: [0, 1, 3, 5, 7, 8, 10, 12, 14, 15],
      ),
      // Mid-morning online — Mon, Wed, Fri, Sun
      _SlotTemplate(
        hour: 10,
        durationMins: 60,
        sessionType: 'online',
        location: 'Online (Zoom)',
        dayOffsets: [0, 2, 4, 6, 7, 9, 11, 13, 14, 16],
      ),
      // Evening group class — Tue, Thu, Sat
      _SlotTemplate(
        hour: 18,
        durationMins: 60,
        sessionType: 'group',
        location: 'Nyali Wellness Studio',
        dayOffsets: [1, 3, 5, 8, 10, 12, 15, 17, 19],
      ),
    ],
  ),

  // ── Kevin Ochieng ────────────────────────────────────────────────────────
  _TrainerSeed(
    id: 'trainer_kevin_ochieng',
    displayName: 'Kevin Ochieng',
    specialties: [
      'Functional Fitness',
      'Calisthenics',
      'Athletic Performance',
      'Mobility'
    ],
    certifications: ['NASM-CPT', 'Functional Movement Specialist', 'CrossFit L2'],
    bio:
        'I grew up running on the coast and competing in athletics through '
        'university. Now I bring that athletic foundation to everyone from '
        'office workers with stiff hips to competitive runners chasing PRs. '
        'No machines needed — functional movement, bodyweight mastery, and '
        'outdoor training at Likoni Waterfront. If you want to move better, '
        'feel stronger, and actually enjoy training, let\'s talk.',
    locationName: 'Likoni Waterfront Grounds',
    rating: 4.8,
    reviewCount: 55,
    priceKes: 1500,
    lat: -4.0810,
    lng: 39.6630,
    yearsExperience: 4,
    slotTemplates: [
      // Sunrise outdoor sessions — daily for first week
      _SlotTemplate(
        hour: 6,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Likoni Waterfront Grounds',
        dayOffsets: [0, 1, 2, 3, 4, 5, 6],
      ),
      // Morning group bootcamp — second week onwards
      _SlotTemplate(
        hour: 8,
        durationMins: 60,
        sessionType: 'group',
        location: 'Likoni Waterfront Grounds',
        dayOffsets: [7, 8, 9, 10, 11, 12, 13, 14, 15],
      ),
      // Afternoon online coaching — Mon, Wed, Fri
      _SlotTemplate(
        hour: 16,
        durationMins: 60,
        sessionType: 'online',
        location: 'Online (Google Meet)',
        dayOffsets: [0, 2, 4, 7, 9, 11, 14, 16, 18],
      ),
    ],
  ),

  // ── Grace Wanjiru ────────────────────────────────────────────────────────
  _TrainerSeed(
    id: 'trainer_grace_wanjiru',
    displayName: 'Grace Wanjiru',
    specialties: [
      'Cardio',
      'Dance Fitness',
      'Body Composition',
      'Zumba',
      'Weight Management'
    ],
    certifications: ['AFAA Group Fitness', 'Zumba Instructor', 'ACE Health Coach'],
    bio:
        'Exercise should never feel like punishment — that\'s the belief that '
        'drives every session I run. My background in dance means training with '
        'me is genuinely fun: high energy, great music, and results you can see. '
        'I\'ve guided over 80 clients through body composition transformations at '
        'Voyager Beach Hotel Gym. Assessments available on Sundays for new clients '
        'who want a personalised starting point.',
    locationName: 'Voyager Beach Hotel Gym',
    rating: 4.6,
    reviewCount: 38,
    priceKes: 2200,
    lat: -3.9888,
    lng: 39.7167,
    yearsExperience: 6,
    slotTemplates: [
      // Morning personal — Mon, Wed, Fri
      _SlotTemplate(
        hour: 8,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Voyager Beach Hotel Gym',
        dayOffsets: [0, 2, 4, 7, 9, 11, 14, 16, 18],
      ),
      // Mid-morning group dance fitness — Tue, Thu, Sat
      _SlotTemplate(
        hour: 10,
        durationMins: 45,
        sessionType: 'group',
        location: 'Voyager Beach Hotel Gym',
        dayOffsets: [1, 3, 5, 8, 10, 12, 15, 17, 19],
      ),
      // Evening personal — Mon, Tue, Thu, Sat
      _SlotTemplate(
        hour: 17,
        durationMins: 60,
        sessionType: 'personal',
        location: 'Voyager Beach Hotel Gym',
        dayOffsets: [0, 1, 3, 5, 7, 8, 10, 12, 14],
      ),
      // Sunday fitness assessment (biweekly)
      _SlotTemplate(
        hour: 7,
        durationMins: 90,
        sessionType: 'assessment',
        location: 'Voyager Beach Hotel Gym',
        dayOffsets: [6, 13, 20],
      ),
    ],
  ),
];

class SeedService {
  static final _db = FirebaseFirestore.instance;

  /// Seeds trainer profiles and availability slots.
  ///
  /// IDEMPOTENT: Slot document IDs are deterministic — derived from
  /// `trainerId + dayOffset + hour`. Calling this multiple times rewrites
  /// the same documents rather than creating duplicates. Safe to call on
  /// every cold start during development.
  static Future<void> ensureSeeded() async {
    try {
      // Firestore max batch size is 500 operations. Split into chunks.
      var batch = _db.batch();
      int opCount = 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final trainer in _kTrainers) {
        // ── Trainer document ──────────────────────────────────────────
        final tRef = _db.collection('trainers').doc(trainer.id);
        batch.set(tRef, {
          'displayName': trainer.displayName,
          'photoUrl': null,
          'specialties': trainer.specialties,
          'certifications': trainer.certifications,
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
        opCount++;

        // ── Availability slots ────────────────────────────────────────
        for (final t in trainer.slotTemplates) {
          for (final d in t.dayOffsets) {
            final slotDate = today.add(Duration(days: d));
            final slotStart = DateTime(
                slotDate.year, slotDate.month, slotDate.day, t.hour);

            // Skip slots that have already passed
            if (slotStart.isBefore(now)) continue;

            final slotEnd =
                slotStart.add(Duration(minutes: t.durationMins));

            // ── DETERMINISTIC ID ──────────────────────────────────────
            // Format: slot_{trainerId}_{dayOffset}_{hour}
            // This guarantees one document per (trainer, day, hour) combo
            // so re-seeding overwrites rather than duplicates.
            final slotId =
                'slot_${trainer.id}_d${d.toString().padLeft(2, '0')}_h${t.hour.toString().padLeft(2, '0')}';

            final sRef =
                _db.collection('availability').doc(slotId);
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
            opCount++;

            // Firestore batch limit is 500 — flush and start a new batch
            if (opCount >= 490) {
              await batch.commit();
              batch = _db.batch();
              opCount = 0;
            }
          }
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[SeedService] Non-fatal: $e');
    }
  }
}