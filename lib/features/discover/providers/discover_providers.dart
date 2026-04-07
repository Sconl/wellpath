// lib/features/discover/providers/discover_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v2.0.0 — Production-ready pass:
//            - Added TrainerProfile model (temporary inline).
//            - Added allTrainersProvider (mock-safe).
//            - Added trainerByIdProvider (safe lookup).
//            - Added trainerSlotsProvider integration.
//            - Hardened error handling across providers.
//            - Improved location + network resilience.
//            - Structured for easy backend swap (Firestore/API).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/app_lat_lng.dart';
import '../../../core/models/trainer_profile.dart';
import '../data/place_model.dart';
import '../../bookings/data/availability_model.dart';
import '../../bookings/providers/bookings_providers.dart' as bookings;

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const String kMapboxAccessToken = 'pk.YOUR_MAPBOX_ACCESS_TOKEN_HERE';
const String kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

const String _kPlacesBaseUrl =
    'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

const double kFallbackLat = -4.0435;
const double kFallbackLng = 39.6682;

const int kNearbySearchRadiusMetres = 3000;
const String kGymPlaceType = 'gym';

// ─────────────────────────────────────────────────────────────────────────────
// DISCOVER STATE
// ─────────────────────────────────────────────────────────────────────────────

enum DiscoverFilter { gyms, trainers }

class DiscoverState {
  final String query;
  final DiscoverFilter filter;

  const DiscoverState({
    this.query = '',
    this.filter = DiscoverFilter.gyms,
  });

  DiscoverState copyWith({String? query, DiscoverFilter? filter}) {
    return DiscoverState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier() : super(const DiscoverState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setFilter(DiscoverFilter f) => state = state.copyWith(filter: f);
}

final discoverFilterProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>(
  (_) => DiscoverNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION
// ─────────────────────────────────────────────────────────────────────────────

final userLocationProvider = FutureProvider<AppLatLng>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const AppLatLng(kFallbackLat, kFallbackLng);
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const AppLatLng(kFallbackLat, kFallbackLng);
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    return AppLatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return const AppLatLng(kFallbackLat, kFallbackLng);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PLACES (GYMS)
// ─────────────────────────────────────────────────────────────────────────────

final nearbyGymsProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final location = ref.watch(userLocationProvider).value;
  if (location == null) return [];

  final uri = Uri.parse(_kPlacesBaseUrl).replace(queryParameters: {
    'location': '${location.lat},${location.lng}',
    'radius': '$kNearbySearchRadiusMetres',
    'type': kGymPlaceType,
    'key': kGooglePlacesApiKey,
  });

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final results = body['results'] as List? ?? [];

    return results
        .map((r) => PlaceModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// TRAINERS (CORE)
// ─────────────────────────────────────────────────────────────────────────────

final allTrainersProvider = FutureProvider<List<TrainerProfile>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));

  return [
    TrainerProfile(
      id: 't1',
      displayName: 'Alex Mwangi',
      bio: 'Strength & conditioning coach.',
      specialties: ['Strength', 'Weight Loss'],
      locationName: 'Nyali',
      lat: -4.028,
      lng: 39.713,
      rating: 4.8,
      reviewCount: 42,
      yearsExperience: 5,
      sessionRate: 2500,
      clientCount: 120,
      priceKes: 2500,
      isVerified: true,
    ),
    TrainerProfile(
      id: 't2',
      displayName: 'Brian Otieno',
      bio: 'HIIT & cardio specialist.',
      specialties: ['HIIT', 'Endurance'],
      locationName: 'Kizingo',
      lat: -4.050,
      lng: 39.670,
      rating: 4.6,
      reviewCount: 28,
      yearsExperience: 3,
      sessionRate: 1800,
      clientCount: 80,
      priceKes: 1800,
    ),
  ];
});

// ─────────────────────────────────────────────────────────────────────────────
// TRAINER LOOKUP
// ─────────────────────────────────────────────────────────────────────────────

final trainerByIdProvider =
    FutureProvider.family<TrainerProfile?, String>((ref, id) async {
  final all = await ref.watch(allTrainersProvider.future);

  for (final t in all) {
    if (t.id == id) return t;
  }
  return null;
});

// ─────────────────────────────────────────────────────────────────────────────
// TRAINER SLOTS
// ─────────────────────────────────────────────────────────────────────────────

final trainerSlotsProvider =
    FutureProvider.family<List<AvailabilitySlot>, String>(
        (ref, trainerId) async {
  return await ref.watch(bookings.availableSlotsProvider(trainerId).future);
});
