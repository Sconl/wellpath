// lib/spaces/space_site/space_site_config.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Site — Config Data Models
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/navigation/nav_items.dart';
import '../../core/style/app_motion.dart';

export '../../core/navigation/nav_items.dart' show MarketingNavItem;
export '../../core/style/app_motion.dart'     show TypingTextConfig;

// ─────────────────────────────────────────────────────────────────────────────
// SpaceSiteStat — supports count-up animation and future backend wiring
// ─────────────────────────────────────────────────────────────────────────────
//
// BACKEND WIRING (future)
//   1. Add a Riverpod provider: `final statsProvider = FutureProvider<List<SpaceSiteStat>>(...)`
//   2. In SiteStatsStrip, replace `config.stats` with `ref.watch(statsProvider).value`
//   3. [numericValue] drives the count-up animation; [display] is the fallback
//      label when animation is off or the value is non-numeric.

class SpaceSiteStat {
  /// Full display string (e.g. "12+"). Shown as static label and as the final
  /// animated value. Keep this consistent with [numericValue] + [suffix].
  final String display;

  /// Numeric portion for the count-up animation (e.g. 12).
  final int numericValue;

  /// Suffix appended after the number during animation (e.g. "+" or "%").
  final String suffix;

  /// Two-line label below the number.
  final String label;

  const SpaceSiteStat({
    required this.display,
    required this.numericValue,
    required this.suffix,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Atomic data models
// ─────────────────────────────────────────────────────────────────────────────

class SpaceSiteStep {
  final String number;
  final String title;
  final String body;
  final IconData icon;
  const SpaceSiteStep({
    required this.number, required this.title,
    required this.body,   required this.icon,
  });
}

class SpaceSiteFeature {
  final IconData icon;
  final String title;
  final String body;
  final bool useSecondaryAccent;
  const SpaceSiteFeature({
    required this.icon, required this.title, required this.body,
    this.useSecondaryAccent = false,
  });
}

class SpaceSiteTestimonial {
  final String quote;
  final String name;
  final String location;
  final String initials;
  const SpaceSiteTestimonial({
    required this.quote, required this.name,
    required this.location, required this.initials,
  });
}

class SpaceSiteFooterLink {
  final String label;
  final String route;
  const SpaceSiteFooterLink({required this.label, required this.route});
}

class SpaceSiteFooterColumn {
  final String title;
  final List<SpaceSiteFooterLink> links;
  const SpaceSiteFooterColumn({required this.title, required this.links});
}

// ─────────────────────────────────────────────────────────────────────────────
// Section configs
// ─────────────────────────────────────────────────────────────────────────────

class SiteNavConfig {
  final List<MarketingNavItem> navItems;
  final String ctaLabel;
  final IconData profileIcon;
  final String profileTooltip;

  const SiteNavConfig({
    this.navItems          = kDefaultMarketingNavItems,
    required this.ctaLabel,
    this.profileIcon       = Icons.person_outline,
    this.profileTooltip    = 'Sign in or create an account',
  });
}

class SiteHeroConfig {
  final String badge;
  final TypingTextConfig headline;
  final String subline;
  final String primaryCtaLabel;
  final String secondaryCtaLabel;
  final String microcopy;

  const SiteHeroConfig({
    required this.badge,
    required this.headline,
    required this.subline,
    required this.primaryCtaLabel,
    required this.secondaryCtaLabel,
    this.microcopy = 'Free to join · No credit card required · Cancel anytime',
  });
}

class SiteTrustedConfig {
  final String label;
  final List<String> logos;
  final Duration scrollDuration;

  const SiteTrustedConfig({
    required this.logos,
    this.label          = 'Trusted by',
    this.scrollDuration = const Duration(seconds: 22),
  });
}

/// Three stats recommended. [stats] list drives the count-up animation.
class SiteStatsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SpaceSiteStat> stats;

  const SiteStatsConfig({
    required this.eyebrow,    required this.heading,
    required this.subheading, required this.stats,
  });
}

class SiteStepsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SpaceSiteStep> steps;

  const SiteStepsConfig({
    required this.eyebrow,    required this.heading,
    required this.subheading, required this.steps,
  });
}

class SiteFeaturesConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SpaceSiteFeature> features;

  const SiteFeaturesConfig({
    required this.eyebrow,    required this.heading,
    required this.subheading, required this.features,
  });
}

class SiteTestimonialsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SpaceSiteTestimonial> testimonials;

  const SiteTestimonialsConfig({
    required this.eyebrow,    required this.heading,
    required this.subheading, required this.testimonials,
  });
}

class SiteCtaConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final String buttonLabel;

  const SiteCtaConfig({
    required this.eyebrow,    required this.heading,
    required this.subheading, required this.buttonLabel,
  });
}

class SiteFooterConfig {
  final String tagline;
  final String location;
  final List<SpaceSiteFooterColumn> columns;
  final String copyright;

  const SiteFooterConfig({
    required this.tagline, required this.location,
    required this.columns, required this.copyright,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SpaceSiteConfig
// ─────────────────────────────────────────────────────────────────────────────

class SpaceSiteConfig {
  final SiteNavConfig          nav;
  final SiteHeroConfig         hero;
  final SiteTrustedConfig      trusted;
  final SiteStatsConfig        stats;
  final SiteStepsConfig   steps;
  final SiteFeaturesConfig     features;
  final SiteTestimonialsConfig testimonials;
  final SiteCtaConfig          cta;
  final SiteFooterConfig       footer;
  final String signupRoute;
  final String loginRoute;
  final String featuresRoute;
  final double pageMaxWidth;
  final double pagePaddingH;

  const SpaceSiteConfig({
    required this.nav, required this.hero, required this.trusted,
    required this.stats, required this.steps, required this.features,
    required this.testimonials, required this.cta, required this.footer,
    this.signupRoute   = '/signup',
    this.loginRoute    = '/login',
    this.featuresRoute = '/features',
    this.pageMaxWidth  = 1100.0,
    this.pagePaddingH  = 60.0,
  });
}

typedef SpaceSiteNavConfig = SiteNavConfig;