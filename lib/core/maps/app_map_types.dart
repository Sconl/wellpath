// lib/core/maps/app_map_types.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Shared types for the dual-engine map system.
//            No SDK imports anywhere in this file — it's the contract
//            between the feature layer and the map implementation layer.
//            Both mobile (Mapbox) and web (flutter_map) implementations
//            satisfy this contract identically.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// AppMapPin — a single annotated location on the map.
//
// Deliberately a plain data class. No SDK types. The implementation layer
// converts to whatever the underlying map SDK needs (CircleAnnotationOptions
// on Mapbox, CircleMarker on flutter_map) at the call site.
// ─────────────────────────────────────────────────────────────────────────────

class AppMapPin {
  final String id;    // unique — used to diff when refreshing pins
  final double lat;
  final double lng;
  final bool   selected;  // drives color/size distinction in both engines

  const AppMapPin({
    required this.id,
    required this.lat,
    required this.lng,
    this.selected = false,
  });

  // Rebuild with a different selected state without touching lat/lng/id.
  AppMapPin copyWith({bool? selected}) => AppMapPin(
    id:       id,
    lat:      lat,
    lng:      lng,
    selected: selected ?? this.selected,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppMapController — the contract both engines satisfy.
//
// Callers (discover_screen, home_screen) use this type only — they never
// import mapbox_maps_flutter or flutter_map directly. That keeps the feature
// layer fully platform-agnostic: swap the engine, nothing in the feature
// layer changes.
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppMapController {
  /// Animate the camera to the given coordinate.
  /// [zoom] is optional — omit to keep the current zoom level.
  Future<void> animateTo(double lat, double lng, {double? zoom});

  /// Replace all pins currently on the map with [pins].
  /// Calling with an empty list clears all pins.
  Future<void> setPins(List<AppMapPin> pins);
}