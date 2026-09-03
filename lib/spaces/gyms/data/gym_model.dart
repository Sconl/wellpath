// lib/features/gyms/data/gym_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. GymModel for the Gyms discovery screen.
//            Data comes from kSampleGyms in gym_providers.dart (MVP).
//            TODO (Week 6+): Replace kSampleGyms with a Firestore-backed
//            gyms collection or Google Places API when billing is confirmed.
//
//   FIELDS:
//   isOpen    — computed from current time vs openHoursStart/End or static bool.
//   category  — matches _kCategories in gyms_screen.dart for filter chips.
//   amenities — up to 8 tags shown in card and detail sheet.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// GymModel
// ─────────────────────────────────────────────────────────────────────────────

class GymModel {
  final String       id;
  final String       name;
  final double       lat;
  final double       lng;
  final double?      rating;
  final int?         userRatingsTotal;
  final String       category;    // matches filter chip labels in gyms_screen
  final List<String> amenities;
  final String       shortAddress; // "Tudor, Mombasa" — used in list card
  final String       fullAddress;  // full street address — used in detail sheet
  final String?      phone;
  final String?      openHours;   // "6:00 AM – 10:00 PM" display string

  // isOpen is a pre-computed value for MVP simplicity.
  // Production: compute from current time vs openHoursStart/openHoursEnd fields.
  final bool         isOpen;

  const GymModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    required this.category,
    required this.amenities,
    required this.shortAddress,
    required this.fullAddress,
    this.phone,
    this.openHours,
    required this.isOpen,
  });
}