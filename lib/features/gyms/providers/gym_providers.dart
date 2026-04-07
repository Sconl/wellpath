// lib/features/gyms/providers/gym_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gym_model.dart';

// ── All gyms — backed by sample data (swap for Firestore stream later) ──────
final allGymsProvider = Provider<List<GymModel>>((ref) => kSampleGyms);

// ── Search-filtered gyms ─────────────────────────────────────────────────────
final gymSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredGymsProvider = Provider<List<GymModel>>((ref) {
  final all = ref.watch(allGymsProvider);
  final q = ref.watch(gymSearchQueryProvider).toLowerCase().trim();
  if (q.isEmpty) return all;
  return all
      .where((g) =>
          g.name.toLowerCase().contains(q) ||
          g.shortAddress.toLowerCase().contains(q) ||
          g.category.toLowerCase().contains(q) ||
          g.amenities.any((a) => a.toLowerCase().contains(q)))
      .toList();
});

// ── Selected gym (for map pin → card highlight sync) ─────────────────────────
final selectedGymIdProvider = StateProvider<String?>((ref) => null);