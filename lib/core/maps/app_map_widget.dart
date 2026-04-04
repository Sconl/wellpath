// lib/core/maps/app_map_widget.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Conditional export orchestrator for the dual-engine
//            map system. Dart's conditional import resolves at compile time —
//            no runtime branching, no dead code in the final binary.
//
//            dart.library.html is only present in web builds. This is the
//            standard Flutter pattern for platform-specific implementations.
//
//   USAGE — import only this file everywhere in the feature layer:
//     import 'package:wellpath/core/maps/app_map_widget.dart';
//
//   WHAT YOU GET:
//     AppMapWidget  — the right map for the platform
//     AppMapController, AppMapPin — from app_map_types.dart (re-exported)
// ─────────────────────────────────────────────────────────────────────────────

// Re-export the types so callers only need one import.
export 'app_map_types.dart';

// The engine. Dart's conditional export selects at compile time:
//   web build   → dart.library.html is present → web_map.dart (flutter_map + OSM)
//   mobile build → dart.library.html is absent  → mobile_map.dart (Mapbox)
export 'impl/mobile_map.dart'
    if (dart.library.html) 'impl/web_map.dart';