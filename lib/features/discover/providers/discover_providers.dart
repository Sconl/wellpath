// lib/features/discover/providers/discover_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Location + Places API providers + discover UI state.
//   v1.1.0 — Renamed LatLng → AppLatLng to prevent ambiguous_import collision
//            when discover_providers is imported alongside mapbox_maps_flutter,
//            which exports its own position types. The custom value object is
//            intentionally lean — it carries coords through the provider layer
//            without coupling to any map SDK.
//          — Split kGoogleMapsApiKey into kMapboxAccessToken (map display)
//            and kGooglePlacesApiKey (Places Nearby Search data). Two services,
//            two keys — clearer and easier to rotate independently.
//
//   ⚠️  SETUP REQUIRED:
//        1. Replace kMapboxAccessToken below with your Mapbox public token.
//           Also call MapboxOptions.setAccessToken(kMapboxAccessToken) in
//           main.dart BEFORE runApp().
//        2. Replace kGooglePlacesApiKey with your Google Cloud key that has
//           "Places API" (classic v1) enabled.
//        3. pubspec.yaml — add:
//             mapbox_maps_flutter: ^2.0.0
//             geolocator: ^12.0.0
//             http: ^1.2.0
//             url_launcher: ^6.3.0
//           Remove google_maps_flutter.
//        4. Android: add to android/local.properties:
//             MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token
//           and to android/app/src/main/res/values/strings.xml:
//             <string name="mapbox_access_token">pk.your_public_token</string>
//        5. iOS: add to ios/Runner/Info.plist:
//             <key>MBXAccessToken</key>
//             <string>pk.your_public_token</string>
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../data/place_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── API keys ──
// ⚠️  Replace both before going live. Move to --dart-define or a secrets
//     manager so they don't sit in source control in production.

// Mapbox public token — used by the map widgets.
// Also set via MapboxOptions.setAccessToken() in main.dart.
const String kMapboxAccessToken = 'pk.YOUR_MAPBOX_ACCESS_TOKEN_HERE';

// Google Places API key — Nearby Search only. Map display is Mapbox.
const String kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

// ── Places endpoint ──
const String _kPlacesBaseUrl =
    'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

// ── Fallback location — Mombasa CBD ──
// Used when GPS is unavailable. Raw doubles so they're const-compatible —
// no SDK type leaks into this config block.
const double kFallbackLat = -4.0435;
const double kFallbackLng = 39.6682;

// ─────────────────────────────────────────────────────────────────────────────
// AppLatLng — thin coordinate value object
//
// Not using any map SDK type here intentionally. Provider layer stays SDK-
// agnostic. Widgets convert to mapbox_maps_flutter's Position at the call site.
// Named AppLatLng (not LatLng) to avoid import ambiguity with any map package.
// ─────────────────────────────────────────────────────────────────────────────

class AppLatLng {
  final double lat;
  final double lng;
  const AppLatLng(this.lat, this.lng);

  // True when we fell back to the default — lets the UI show the banner.
  bool get isFallback => lat == kFallbackLat && lng == kFallbackLng;
}

// ─────────────────────────────────────────────────────────────────────────────
// DiscoverFilter + DiscoverState
// ─────────────────────────────────────────────────────────────────────────────

enum DiscoverFilter { gyms, trainers }

class DiscoverState {
  final String         query;
  final DiscoverFilter filter;

  const DiscoverState({
    this.query  = '',
    this.filter = DiscoverFilter.gyms,
  });

  DiscoverState copyWith({String? query, DiscoverFilter? filter}) {
    return DiscoverState(
      query:  query  ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier() : super(const DiscoverState());

  void setQuery(String q)          => state = state.copyWith(query: q);
  void setFilter(DiscoverFilter f) => state = state.copyWith(filter: f);
}

final discoverFilterProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>(
  (_) => DiscoverNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// userLocationProvider — one-shot GPS resolve per session.
// Degrades gracefully to Mombasa CBD — the screen is never broken by a denial.
// ─────────────────────────────────────────────────────────────────────────────

final userLocationProvider = FutureProvider<AppLatLng>((ref) async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return const AppLatLng(kFallbackLat, kFallbackLng);

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return const AppLatLng(kFallbackLat, kFallbackLng);
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return const AppLatLng(kFallbackLat, kFallbackLng);
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit:       const Duration(seconds: 10),
    );
    return AppLatLng(pos.latitude, pos.longitude);
  } catch (_) {
    // Timeout or hardware error — silent fallback.
    return const AppLatLng(kFallbackLat, kFallbackLng);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// nearbyGymsProvider — Google Places Nearby Search, type=gym.
// Returns [] on any network or parse failure — no error state propagated.
// ─────────────────────────────────────────────────────────────────────────────

final nearbyGymsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final location = ref.watch(userLocationProvider).value;
  if (location == null) return [];   // still resolving — caller shows shimmer

  final uri = Uri.parse(_kPlacesBaseUrl).replace(queryParameters: {
    'location': '${location.lat},${location.lng}',
    'radius':   '$kNearbySearchRadiusMetres',
    'type':     kGymPlaceType,
    'key':      kGooglePlacesApiKey,
  });

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return [];

    final body    = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List? ?? [];
    return results
        .map((r) => PlaceModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});