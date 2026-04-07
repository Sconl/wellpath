// lib/features/gyms/data/gym_model.dart

class GymModel {
  final String id;
  final String name;
  final String shortAddress;
  final String fullAddress;
  final double lat;
  final double lng;
  final double? rating;
  final int? userRatingsTotal;
  final bool isOpen;
  final String? openHours;
  final List<String> amenities;
  final String category; // e.g. "CrossFit", "Yoga", "Weights & Cardio"
  final String? phone;
  final String? website;
  final String? imageUrl;

  const GymModel({
    required this.id,
    required this.name,
    required this.shortAddress,
    required this.fullAddress,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    required this.isOpen,
    this.openHours,
    required this.amenities,
    required this.category,
    this.phone,
    this.website,
    this.imageUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Sample data — Mombasa CBD & surrounds
// ─────────────────────────────────────────────────────────────────────────────

const List<GymModel> kSampleGyms = [
  GymModel(
    id: 'gym_001',
    name: 'Ironclad Fitness Centre',
    shortAddress: 'Moi Avenue, Mombasa CBD',
    fullAddress: 'Ambalal House, Moi Avenue, Mombasa 80100',
    lat: -4.0487,
    lng: 39.6671,
    rating: 4.6,
    userRatingsTotal: 312,
    isOpen: true,
    openHours: 'Mon–Sat 5:30 AM – 10 PM · Sun 7 AM – 6 PM',
    amenities: ['Free Weights', 'Cardio Zone', 'Sauna', 'Lockers', 'Parking'],
    category: 'Weights & Cardio',
    phone: '+254 712 345 678',
    website: 'https://ironclad.co.ke',
  ),
  GymModel(
    id: 'gym_002',
    name: 'CrossFit Mombasa',
    shortAddress: 'Nyali Road, Nyali',
    fullAddress: 'Nyali Centre, Nyali Road, Mombasa 80118',
    lat: -4.0213,
    lng: 39.7012,
    rating: 4.8,
    userRatingsTotal: 187,
    isOpen: true,
    openHours: 'Mon–Fri 5 AM – 9 PM · Sat–Sun 6 AM – 4 PM',
    amenities: ['CrossFit Rig', 'Open Box', 'Olympic Lifting', 'Coaching'],
    category: 'CrossFit',
    phone: '+254 722 456 789',
    website: 'https://crossfitmombasa.co.ke',
  ),
  GymModel(
    id: 'gym_003',
    name: 'Serenity Yoga & Wellness',
    shortAddress: 'Diani Beach Road, Diani',
    fullAddress: 'Diani Beachalets, Diani Beach Road, Kwale 80401',
    lat: -4.2791,
    lng: 39.5899,
    rating: 4.9,
    userRatingsTotal: 94,
    isOpen: false,
    openHours: 'Daily 6 AM – 8 PM',
    amenities: ['Yoga Studio', 'Meditation Room', 'Spa', 'Open-Air Deck'],
    category: 'Yoga & Wellness',
    phone: '+254 733 567 890',
    website: 'https://serenitymombasa.co.ke',
  ),
  GymModel(
    id: 'gym_004',
    name: 'Palace Fitness & Spa',
    shortAddress: 'Links Road, Nyali',
    fullAddress: 'Palace Hotel, Links Road, Nyali, Mombasa 80118',
    lat: -4.0152,
    lng: 39.7189,
    rating: 4.4,
    userRatingsTotal: 228,
    isOpen: true,
    openHours: 'Daily 6 AM – 10 PM',
    amenities: ['Pool', 'Spa', 'Cardio', 'Weights', 'Tennis Courts', 'Sauna'],
    category: 'Hotel Gym & Spa',
    phone: '+254 741 678 901',
  ),
  GymModel(
    id: 'gym_005',
    name: 'Urban Sweat Studio',
    shortAddress: 'Mombasa Road, Kilindini',
    fullAddress: 'Mombasa Trade Centre, Mombasa Road, Kilindini 80100',
    lat: -4.0641,
    lng: 39.6558,
    rating: 4.2,
    userRatingsTotal: 156,
    isOpen: true,
    openHours: 'Mon–Sat 5 AM – 9 PM · Sun 8 AM – 5 PM',
    amenities: ['HIIT Classes', 'Spin Bikes', 'Functional Training', 'Showers'],
    category: 'Boutique Studio',
    phone: '+254 700 789 012',
  ),
  GymModel(
    id: 'gym_006',
    name: 'Peak Performance Gym',
    shortAddress: 'Mama Ngina Drive, CBD',
    fullAddress: 'Mama Ngina Drive, Mombasa CBD, Mombasa 80100',
    lat: -4.0602,
    lng: 39.6644,
    rating: 4.5,
    userRatingsTotal: 274,
    isOpen: false,
    openHours: 'Mon–Fri 5:30 AM – 9:30 PM · Sat 6 AM – 6 PM · Sun Closed',
    amenities: ['Powerlifting', 'Bodybuilding Zone', 'Protein Bar', 'PT Sessions'],
    category: 'Powerlifting & Bodybuilding',
    phone: '+254 711 890 123',
  ),
  GymModel(
    id: 'gym_007',
    name: 'Swahili Coast MMA & Boxing',
    shortAddress: 'Makupa Road, Makupa',
    fullAddress: 'Makupa Plaza, Makupa Road, Mombasa 80100',
    lat: -4.0512,
    lng: 39.6401,
    rating: 4.7,
    userRatingsTotal: 118,
    isOpen: true,
    openHours: 'Mon–Sat 6 AM – 9 PM',
    amenities: ['Boxing Ring', 'MMA Mats', 'Bag Work', 'Sparring', 'Kids Classes'],
    category: 'Combat Sports',
    phone: '+254 722 901 234',
  ),
  GymModel(
    id: 'gym_008',
    name: 'Bahari Wellness Club',
    shortAddress: 'Shanzu Road, Shanzu',
    fullAddress: 'Bahari Beach Hotel, Shanzu Road, Mombasa 80105',
    lat: -3.9788,
    lng: 39.7218,
    rating: 4.3,
    userRatingsTotal: 67,
    isOpen: true,
    openHours: 'Daily 6 AM – 9 PM',
    amenities: ['Beach Access', 'Pool', 'Yoga', 'Gym Floor', 'Nutrition Advice'],
    category: 'Beach & Wellness',
    phone: '+254 733 012 345',
  ),
];