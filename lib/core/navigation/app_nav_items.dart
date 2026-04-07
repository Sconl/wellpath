// lib/core/navigation/app_nav_items.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v3.1.0 — Single source of truth for navigation items.
//            Moved from app_nav.dart to dedicated file for better organization.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NavItem
// ─────────────────────────────────────────────────────────────────────────────

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// ── User nav ──────────────────────────────────────────────────────────────────
const kUserNavItems = <NavItem>[
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
    route: '/home',
  ),
  NavItem(
    icon: Icons.search_outlined,
    activeIcon: Icons.search_rounded,
    label: 'Trainers',
    route: '/trainers',
  ),
  NavItem(
    icon: Icons.location_on_outlined,
    activeIcon: Icons.location_on_rounded,
    label: 'Gyms',
    route: '/gyms',
  ),
  NavItem(
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label: 'Bookings',
    route: '/bookings',
  ),
  NavItem(
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
    label: 'Wellness',
    route: '/wellness',
  ),
  NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    route: '/profile',
  ),
];

// ── Trainer nav ───────────────────────────────────────────────────────────────
const kTrainerNavItems = <NavItem>[
  NavItem(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    label: 'Dashboard',
    route: '/home', // redirects to /trainer-dashboard
  ),
  NavItem(
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label: 'Bookings',
    route: '/bookings',
  ),
  NavItem(
    icon: Icons.event_available_outlined,
    activeIcon: Icons.event_available_rounded,
    label: 'Availability',
    route: '/availability',
  ),
  NavItem(
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
    label: 'Wellness',
    route: '/wellness',
  ),
  NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    route: '/profile',
  ),
];
