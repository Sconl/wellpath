// lib/features/discover/providers/discover_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. GPS + Google Places nearby gyms + filter state.
//   v1.1.0 — Added allTrainersProvider + trainerByIdProvider. Trainer data
//            now Firestore-backed (seeded by SeedService on first launch).
//            AppLatLng moved to lib/core/models/app_lat_lng.dart — import
//            from there, not here. Re-exported for backward compatibility.
//   v1.2.0 — nearbyGymsProvider retained as a stub for future Places API
//            integration on the Gyms screen. Gyms screen currently uses
//            kSampleGyms from gym_providers.dart instead.
//            discoverFilterProvider removed — TrainersScreen and
//            DiscoverScreen do client-side text filtering instead.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/app_lat_lng.dart';
import '../../../core/models/trainer_profile.dart';

// Re-export AppLatLng so existing files that import from this path still compile.
export '../../../core/models/app_lat_lng.dart' show AppLatLng;

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// API keys — replace with --dart-define values before production build.
const String kMapboxAccessToken = 'pk.YOUR_MAPBOX_ACCESS_TOKEN_HERE';
const String kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

const String _kPlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
const int kNearbySearchRadiusMetres = 5000;
const String kGymPlaceType = 'gym';

// GPS timeout — if location doesn't resolve in this time, fall back to CBD.
const int _kGpsTimeoutSeconds = 10;

// ─────────────────────────────────────────────────────────────────────────────
// userLocationProvider — GPS with Mombasa CBD fallback
//
// Returns isFallback: true when GPS is denied or times out so feature screens
// can show a location-unavailable banner if desired.
// ─────────────────────────────────────────────────────────────────────────────

final userLocationProvider = FutureProvider<AppLatLng>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return AppLatLng.mombasaCbd;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return AppLatLng.mombasaCbd;
    }
    if (permission == LocationPermission.deniedForever) {
      return AppLatLng.mombasaCbd;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    ).timeout(
      Duration(seconds: _kGpsTimeoutSeconds),
      onTimeout: () => throw Exception('GPS timeout'),
    );

    return AppLatLng(position.latitude, position.longitude);
  } catch (_) {
    return AppLatLng.mombasaCbd;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// allTrainersProvider — real-time stream of all trainers ordered by rating
//
// Used by:
//   - home_screen.dart        (_NearbyMapCard: trainer pins on home map)
//   - discover_screen.dart    (trainer list + map)
//   - trainers_screen.dart    (trainer list + map)
// ─────────────────────────────────────────────────────────────────────────────

final allTrainersProvider = StreamProvider<List<TrainerProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection(kTrainersCollection)
      .orderBy('rating', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(TrainerProfile.fromFirestore).toList());
});

// ─────────────────────────────────────────────────────────────────────────────
// trainerByIdProvider — real-time stream for a single trainer document
//
// Used by:
//   - discover/presentation/trainer_profile_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

final trainerByIdProvider =
    StreamProvider.family<TrainerProfile?, String>((ref, trainerId) {
  if (trainerId.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection(kTrainersCollection)
      .doc(trainerId)
      .snapshots()
      .map((doc) => doc.exists ? TrainerProfile.fromFirestore(doc) : null);
});

// ─────────────────────────────────────────────────────────────────────────────
// nearbyGymsProvider — Google Places Nearby Search for gyms
//
// Currently used as a lightweight pin source for the home map card.
// The Gyms screen (gyms_screen.dart) uses kSampleGyms from gym_providers.dart
// instead, which avoids API quota on every page load.
//
// TODO (Week 6): Wire nearbyGymsProvider to the gyms screen when Places API
// quota and billing are confirmed for production.
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceSummary {
  final String placeId;
  final double lat, lng;
  const _PlaceSummary(this.placeId, this.lat, this.lng);
}

final nearbyGymsProvider = FutureProvider<List<_PlaceSummary>>((ref) async {
  final location = await ref.watch(userLocationProvider.future);

  try {
    final url = Uri.parse(
      '$_kPlacesBaseUrl/nearbysearch/json'
      '?location=${location.lat},${location.lng}'
      '&radius=$kNearbySearchRadiusMetres'
      '&type=$kGymPlaceType'
      '&key=$kGooglePlacesApiKey',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List? ?? [];

    return results.map((r) {
      final geo = r['geometry']['location'] as Map<String, dynamic>;
      return _PlaceSummary(
        r['place_id'] as String,
        (geo['lat'] as num).toDouble(),
        (geo['lng'] as num).toDouble(),
      );
    }).toList();
  } catch (_) {
    return []; // Network / quota failure — never crash the home screen.
  }
});
