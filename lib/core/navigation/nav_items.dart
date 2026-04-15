// lib/core/navigation/nav_items.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Navigation Items — Single Source of Truth
// ─────────────────────────────────────────────────────────────────────────────
//
// WHAT LIVES HERE
//   MarketingNavItem  — a single link in the marketing top nav bar.
//   NavItem           — a single destination in the authenticated app shell
//                       (sidebar / drawer / bottom bar).
//   kDefaultMarketingNavItems — the three standard marketing pages (About,
//                       Features, Pricing). Configurable — pass more items
//                       to MarketingTopNav.navItems when you need them.
//   kUserNavItems     — the six authenticated-user destinations.
//   kTrainerNavItems  — the five trainer-specific destinations.
//
// WHAT DOESN'T LIVE HERE
//   Widget code, routing logic, or anything visual. This file is pure data.
//
// REPLACES
//   lib/core/widgets/app_nav_bar.dart   (AppNavItem class)
//   lib/core/constants/marketing_nav.dart (kMarketingNavItems list)
//   lib/core/navigation/app_nav_items.dart (NavItem class + app lists)
//
// IMPORT PATTERN
//   import 'package:wellpath/core/navigation/nav_items.dart';
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MarketingNavItem
// ─────────────────────────────────────────────────────────────────────────────
//
// One link in the public-facing marketing navigation bar.
// Used by [MarketingTopNav] and [SiteNavConfig].

class MarketingNavItem {
  /// The visible link label, e.g. "About".
  final String label;

  /// The GoRouter route path, e.g. "/about".
  final String route;

  /// Optional override for screen-reader announcements.
  /// Defaults to [label] when null.
  final String? semanticLabel;

  const MarketingNavItem({
    required this.label,
    required this.route,
    this.semanticLabel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// NavItem
// ─────────────────────────────────────────────────────────────────────────────
//
// One destination in the authenticated app navigation shell
// (sidebar / drawer / bottom bar). Used by [AppNavShell].

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

// ─────────────────────────────────────────────────────────────────────────────
// Marketing nav lists
// ─────────────────────────────────────────────────────────────────────────────

/// The three standard marketing destinations.
/// Pass these to [MarketingTopNav.navItems] or override with a custom list.
const List<MarketingNavItem> kDefaultMarketingNavItems = [
  MarketingNavItem(label: 'About',    route: '/about'),
  MarketingNavItem(label: 'Features', route: '/features'),
  MarketingNavItem(label: 'Pricing',  route: '/pricing'),
];

// ─────────────────────────────────────────────────────────────────────────────
// App shell nav lists
// ─────────────────────────────────────────────────────────────────────────────

/// Six-destination user navigation. Used by [AppNavShell] in user mode.
const List<NavItem> kUserNavItems = [
  NavItem(
    icon:       Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label:      'Home',
    route:      '/home',
  ),
  NavItem(
    icon:       Icons.search_outlined,
    activeIcon: Icons.search_rounded,
    label:      'Trainers',
    route:      '/trainers',
  ),
  NavItem(
    icon:       Icons.location_on_outlined,
    activeIcon: Icons.location_on_rounded,
    label:      'Gyms',
    route:      '/gyms',
  ),
  NavItem(
    icon:       Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label:      'Bookings',
    route:      '/bookings',
  ),
  NavItem(
    icon:       Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
    label:      'Wellness',
    route:      '/wellness',
  ),
  NavItem(
    icon:       Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label:      'Profile',
    route:      '/profile',
  ),
];

/// Five-destination trainer navigation. Used by [AppNavShell] in trainer mode.
const List<NavItem> kTrainerNavItems = [
  NavItem(
    icon:       Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    label:      'Dashboard',
    route:      '/home',
  ),
  NavItem(
    icon:       Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label:      'Bookings',
    route:      '/bookings',
  ),
  NavItem(
    icon:       Icons.event_available_outlined,
    activeIcon: Icons.event_available_rounded,
    label:      'Availability',
    route:      '/availability',
  ),
  NavItem(
    icon:       Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
    label:      'Wellness',
    route:      '/wellness',
  ),
  NavItem(
    icon:       Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label:      'Profile',
    route:      '/profile',
  ),
];