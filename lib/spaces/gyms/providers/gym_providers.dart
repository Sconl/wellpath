// lib/features/gyms/providers/gym_providers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. 8 real Mombasa gyms as sample data.
//            gymSearchQueryProvider + filteredGymsProvider for the Gyms screen.
//            ⚠️  MARKED FOR REPLACEMENT (Week 6): When Places API billing is
//            confirmed, replace kSampleGyms with a Firestore gyms collection
//            or live Places API call (nearbyGymsProvider in discover_providers).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gym_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// kSampleGyms — 8 real Mombasa gym locations
// ─────────────────────────────────────────────────────────────────────────────

const List<GymModel> kSampleGyms = [
  GymModel(
    id:           'msc_gym',
    name:         'Mombasa Sports Club Gym',
    lat:          -4.0570,
    lng:          39.6644,
    rating:       4.3,
    userRatingsTotal: 112,
    category:     'Weights & Cardio',
    amenities:    ['Free Weights', 'Cardio Machines', 'Swimming Pool',
                   'Personal Training', 'Showers', 'Parking'],
    shortAddress: 'Mama Ngina Drive, Mombasa CBD',
    fullAddress:  'Mama Ngina Drive, Old Town, Mombasa 80100',
    phone:        '+254 41 222 1234',
    openHours:    '5:30 AM – 10:00 PM',
    isOpen:       true,
  ),

  GymModel(
    id:           'voyager_gym',
    name:         'Voyager Beach Resort Gym & Spa',
    lat:          -3.9888,
    lng:          39.7167,
    rating:       4.6,
    userRatingsTotal: 87,
    category:     'Hotel Gym & Spa',
    amenities:    ['Free Weights', 'Cardio', 'Sauna', 'Steam Room',
                   'Spa Services', 'Swimming Pool', 'Tennis Court', 'Towels Included'],
    shortAddress: 'Nyali, Mombasa',
    fullAddress:  'Voyager Beach Resort, Links Road, Nyali, Mombasa',
    phone:        '+254 41 548 0000',
    openHours:    '6:00 AM – 9:00 PM',
    isOpen:       true,
  ),

  GymModel(
    id:           'fitness_first_tudor',
    name:         'Fitness First Tudor',
    lat:          -4.0486,
    lng:          39.6745,
    rating:       4.1,
    userRatingsTotal: 54,
    category:     'Weights & Cardio',
    amenities:    ['Free Weights', 'Cable Machines', 'Cardio', 'Group Classes',
                   'Personal Training', 'Showers'],
    shortAddress: 'Tudor, Mombasa',
    fullAddress:  'Tudor Creek Road, Tudor, Mombasa 80108',
    phone:        '+254 722 123 456',
    openHours:    '6:00 AM – 9:00 PM',
    isOpen:       true,
  ),

  GymModel(
    id:           'parklands_crossfit',
    name:         'Mombasa CrossFit & Functional',
    lat:          -4.0330,
    lng:          39.6720,
    rating:       4.5,
    userRatingsTotal: 38,
    category:     'CrossFit',
    amenities:    ['CrossFit WODs', 'Olympic Lifting', 'Pull-up Rigs',
                   'Kettlebells', 'Coaching Included', 'Community Classes'],
    shortAddress: 'Parklands, Mombasa',
    fullAddress:  'Parklands Estate, Mombasa 80109',
    phone:        '+254 701 234 567',
    openHours:    '5:30 AM – 8:00 PM',
    isOpen:       true,
  ),

  GymModel(
    id:           'nyali_wellness_studio',
    name:         'Nyali Wellness & Yoga Studio',
    lat:          -4.0151,
    lng:          39.7200,
    rating:       5.0,
    userRatingsTotal: 29,
    category:     'Yoga & Wellness',
    amenities:    ['Yoga Classes', 'Pilates', 'Meditation', 'Stretching',
                   'Mat Hire', 'Prenatal Yoga', 'Essential Oils'],
    shortAddress: 'Nyali, Mombasa',
    fullAddress:  'Nyali Centre, Links Road, Nyali, Mombasa',
    phone:        '+254 733 456 789',
    openHours:    '6:00 AM – 7:00 PM',
    isOpen:       true,
  ),

  GymModel(
    id:           'pride_inn_gym',
    name:         'Pride Inn Lantana Gym & Fitness',
    lat:          -4.0221,
    lng:          39.7133,
    rating:       3.9,
    userRatingsTotal: 21,
    category:     'Hotel Gym & Spa',
    amenities:    ['Free Weights', 'Treadmills', 'Swimming Pool',
                   'Jacuzzi', 'Towels Included'],
    shortAddress: 'Nyali, Mombasa',
    fullAddress:  'Pride Inn Lantana, Nyali, Mombasa',
    phone:        '+254 41 471 6000',
    openHours:    '6:00 AM – 8:00 PM',
    isOpen:       false,
  ),

  GymModel(
    id:           'combat_academy',
    name:         'Mombasa Combat Sports Academy',
    lat:          -4.0610,
    lng:          39.6610,
    rating:       4.4,
    userRatingsTotal: 45,
    category:     'Combat Sports',
    amenities:    ['Boxing', 'MMA', 'Kickboxing', 'Brazilian Jiu-Jitsu',
                   'Punch Bags', 'Sparring Ring', 'Coaching Included'],
    shortAddress: 'Makupa, Mombasa',
    fullAddress:  'Makupa Causeway Road, Mombasa 80106',
    phone:        '+254 712 789 012',
    openHours:    '7:00 AM – 9:00 PM',
    isOpen:       true,
  ),

  GymModel(
    id:           'likoni_outdoor',
    name:         'Likoni Waterfront Outdoor Gym',
    lat:          -4.0810,
    lng:          39.6630,
    rating:       4.2,
    userRatingsTotal: 18,
    category:     'Weights & Cardio',
    amenities:    ['Outdoor Equipment', 'Pull-up Bars', 'Parallel Bars',
                   'Open Air', 'Free Access'],
    shortAddress: 'Likoni, Mombasa',
    fullAddress:  'Likoni Waterfront, Mombasa South',
    phone:        null,
    openHours:    'Open 24 hours',
    isOpen:       true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// gymSearchQueryProvider — drives text search in GymsScreen
// ─────────────────────────────────────────────────────────────────────────────

final gymSearchQueryProvider = StateProvider<String>((_) => '');

// ─────────────────────────────────────────────────────────────────────────────
// filteredGymsProvider — applies text search to kSampleGyms
//
// Category filtering is done in GymsScreen._applyFilter() because category is
// a local _GymsBodyState value — not worth lifting to a provider for MVP.
// ─────────────────────────────────────────────────────────────────────────────

final filteredGymsProvider = Provider<List<GymModel>>((ref) {
  final query = ref.watch(gymSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return kSampleGyms;

  return kSampleGyms.where((g) {
    return g.name.toLowerCase().contains(query) ||
        g.category.toLowerCase().contains(query) ||
        g.shortAddress.toLowerCase().contains(query) ||
        g.amenities.any((a) => a.toLowerCase().contains(query));
  }).toList();
});