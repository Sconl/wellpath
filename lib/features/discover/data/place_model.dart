// lib/features/discover/data/place_model.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. PlaceModel mirrors the Google Places API (Nearby Search)
//            response shape. Covers gyms now; trainer listings will extend
//            this with a TrainerModel overlay in a future sprint.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// Radius (metres) for the nearby gym search. 5 km covers central Mombasa
// without returning gyms in Nairobi. Tune once real-world usage data is in.
const kNearbySearchRadiusMetres = 5000;

// Places API type filter used for the gym search.
const kGymPlaceType = 'gym';

// ─────────────────────────────────────────────────────────────────────────────
// PlaceModel
//
// Intentionally lean — we only decode what the UI actually consumes.
// Add fields as the design evolves; don't pre-map the entire Places schema.
// ─────────────────────────────────────────────────────────────────────────────

class PlaceModel {
  final String  placeId;
  final String  name;
  final String  address;
  final double  lat;
  final double  lng;
  final double? rating;       // null if the place has no ratings yet
  final int?    userRatingsTotal;
  final bool    isOpen;       // based on opening_hours.open_now if present
  final String? photoRef;     // first photo reference, for thumbnail

  const PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    this.isOpen = true,
    this.photoRef,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};
    final photos   = json['photos']   as List?;
    final hours    = json['opening_hours'] as Map<String, dynamic>?;

    return PlaceModel(
      placeId:          json['place_id']     as String? ?? '',
      name:             json['name']         as String? ?? 'Unknown',
      address:          json['vicinity']     as String? ?? '',
      lat:              (location['lat']     as num?)?.toDouble() ?? 0.0,
      lng:              (location['lng']     as num?)?.toDouble() ?? 0.0,
      rating:           (json['rating']      as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      isOpen:           hours?['open_now']   as bool? ?? true,
      photoRef:         photos != null && photos.isNotEmpty
                            ? (photos.first as Map<String, dynamic>)['photo_reference'] as String?
                            : null,
    );
  }

  // Convenience — distance string placeholder until we wire up real distance.
  // The provider can compute this from the user's location once it has both.
  String get shortAddress {
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }
}