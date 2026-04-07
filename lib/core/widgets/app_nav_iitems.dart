// lib/core/navigation/app_nav_items.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Navigation items definition — single source of truth.
// AppNavShell reads from this file to build the drawer / sidebar / bottom bar.
//
// NEW ORDER (v2.0.0):
//   1. Home        /home
//   2. Trainers    /trainers     (was /discover)
//   3. Gyms        /gyms         (NEW)
//   4. Bookings    /bookings
//   5. Wellness    /wellness     (NEW page)
//   6. Profile     /profile
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppNavDestination {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? trainerOnlyAlternativeRoute; // if trainer view replaces this route

  const AppNavDestination({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.trainerOnlyAlternativeRoute,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// User nav items (the 6-item list)
// ─────────────────────────────────────────────────────────────────────────────

const List<AppNavDestination> kUserNavItems = [
  AppNavDestination(
    route: '/home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  AppNavDestination(
    route: '/trainers',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    label: 'Trainers',
  ),
  AppNavDestination(
    route: '/gyms',
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center_rounded,
    label: 'Gyms',
  ),
  AppNavDestination(
    route: '/bookings',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today_rounded,
    label: 'Bookings',
  ),
  AppNavDestination(
    route: '/wellness',
    icon: Icons.self_improvement_outlined,
    activeIcon: Icons.self_improvement_rounded,
    label: 'Wellness',
  ),
  AppNavDestination(
    route: '/profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Trainer nav items (trainer view)
// ─────────────────────────────────────────────────────────────────────────────

const List<AppNavDestination> kTrainerNavItems = [
  AppNavDestination(
    route: '/home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Dashboard',
  ),
  AppNavDestination(
    route: '/bookings',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today_rounded,
    label: 'Bookings',
  ),
  AppNavDestination(
    route: '/availability',
    icon: Icons.event_available_outlined,
    activeIcon: Icons.event_available_rounded,
    label: 'Availability',
  ),
  AppNavDestination(
    route: '/wellness',
    icon: Icons.self_improvement_outlined,
    activeIcon: Icons.self_improvement_rounded,
    label: 'Wellness',
  ),
  AppNavDestination(
    route: '/profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// GoRouter route additions (add to your existing router config)
// ─────────────────────────────────────────────────────────────────────────────
//
// Add these routes to your GoRouter configuration:
//
//   GoRoute(
//     path: '/trainers',
//     builder: (context, state) => const TrainersScreen(),
//   ),
//   GoRoute(
//     path: '/gyms',
//     builder: (context, state) => const GymsScreen(),
//   ),
//   GoRoute(
//     path: '/wellness',
//     builder: (context, state) => const WellnessScreen(),
//   ),
//
// Keep /discover as a redirect for backward compatibility:
//
//   GoRoute(
//     path: '/discover',
//     redirect: (context, state) => '/trainers',
//   ),
//
// Trainer profile route (add back button + book button):
//
//   GoRoute(
//     path: '/trainer/:id',
//     builder: (context, state) => TrainerProfileScreen(
//       trainerId: state.pathParameters['id']!,
//     ),
//   ),