// lib/core/constants/marketing_nav.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Single source of truth for the public marketing navigation.
// Import this wherever AppNavBar needs kMarketingNavItems — landing page,
// about, features, pricing — so all pages share an identical nav bar.
// ─────────────────────────────────────────────────────────────────────────────

import '../widgets/app_nav_bar.dart';

const List<AppNavItem> kMarketingNavItems = [
  AppNavItem(label: 'About',    route: '/about'),
  AppNavItem(label: 'Features', route: '/features'),
  AppNavItem(label: 'Pricing',  route: '/pricing'),
];