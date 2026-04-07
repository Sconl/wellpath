// lib/core/models/app_lat_lng.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Extracted from discover_providers.dart into a shared model so
//            any feature (home, discover, trainers, gyms) can import without
//            creating a dependency on discover_providers.dart.
//            Named AppLatLng (not LatLng) — avoids import collision with
//            mapbox_maps_flutter and latlong2 (Decision 033 in canvas).
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// Mombasa CBD — used as GPS fallback across all map-using features.
const double kFallbackLat = -4.0435;
const double kFallbackLng = 39.6682;

// ─────────────────────────────────────────────────────────────────────────────
// AppLatLng
// ─────────────────────────────────────────────────────────────────────────────

class AppLatLng {
  final double lat;
  final double lng;

  // isFallback: true when GPS was denied/timed-out and we fell back to the
  // default Mombasa CBD coordinates. Feature screens use this flag to decide
  // whether to show a "location unavailable" banner.
  final bool isFallback;

  const AppLatLng(this.lat, this.lng, {this.isFallback = false});

  /// Mombasa CBD fallback — identical to what GPS returns when unavailable.
  static const AppLatLng mombasaCbd =
      AppLatLng(kFallbackLat, kFallbackLng, isFallback: true);

  @override
  String toString() => 'AppLatLng($lat, $lng)';

  @override
  bool operator ==(Object other) =>
      other is AppLatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}