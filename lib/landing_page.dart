// lib/landing_page.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
//   v3.0.0 — Refactored to Site template. All widget/copy code now lives in
//            lib/features/site/. This file is a thin wrapper so the router
//            requires no changes — LandingPage class name is preserved.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'features/site/home/site_landing_page.dart';
import 'features/site/home/wellpath_config.dart';

export 'features/site/home/site_landing_page.dart' show SiteLandingPage;
export 'features/site/site_config.dart';

/// WellPath marketing landing page — delegates to [SiteLandingPage].
/// Preserved as [LandingPage] so the GoRouter config requires no changes.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const SiteLandingPage(config: kWellPathSiteConfig);
}