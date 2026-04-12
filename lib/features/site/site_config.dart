// lib/features/site/site_config.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Site — Universal Marketing Page Template Config
// ─────────────────────────────────────────────────────────────────────────────
//
// Data models only. No widgets here.
// To adapt Site to any product, create a [SiteConfig] instance and pass it
// to [SiteLandingPage]. Zero widget code changes needed between products.
//
// [TypingTextConfig] lives in app_motion.dart — import from there.
//
// SECTION STRUCTURE
//   Every section in Site follows the 4-part convention:
//     1. eyebrow  — short all-caps label ("PLATFORM SNAPSHOT")
//     2. headline — bold marketing statement (h2 scale)
//     3. subline  — grey supporting copy (bodySmall / textSecondary)
//     4. content  — the section's actual widgets (cards, grid, strip etc.)
//
//   In AppTypography terms:
//     eyebrow  → AppTypography.overline  (fontAccent, uppercase, textMuted)
//     headline → AppTypography.h2        (fontDisplay, bold, textPrimary)
//     subline  → AppTypography.bodySmall (fontText, light, textSecondary)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/style/app_motion.dart';
import '../../core/widgets/app_nav_bar.dart';

// Re-export TypingTextConfig for consumers who only import site_config.
export '../../core/style/app_motion.dart' show TypingTextConfig;

// ─────────────────────────────────────────────────────────────────────────────
// Atomic data models
// ─────────────────────────────────────────────────────────────────────────────

class SiteStat {
  final String value;
  final String label;
  const SiteStat({required this.value, required this.label});
}

class SiteStep {
  final String number;
  final String title;
  final String body;
  final IconData icon;
  const SiteStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });
}

/// [useSecondaryAccent] — switches icon/border from primary to secondary color,
/// enabling the alternating-color grid pattern.
class SiteFeature {
  final IconData icon;
  final String title;
  final String body;
  final bool useSecondaryAccent;
  const SiteFeature({
    required this.icon,
    required this.title,
    required this.body,
    this.useSecondaryAccent = false,
  });
}

class SiteTestimonial {
  final String quote;
  final String name;
  final String location;
  final String initials;
  const SiteTestimonial({
    required this.quote,
    required this.name,
    required this.location,
    required this.initials,
  });
}

class SiteFooterLink {
  final String label;
  final String route;
  const SiteFooterLink({required this.label, required this.route});
}

class SiteFooterColumn {
  final String title;
  final List<SiteFooterLink> links;
  const SiteFooterColumn({required this.title, required this.links});
}

// ─────────────────────────────────────────────────────────────────────────────
// Section-level configs
// ─────────────────────────────────────────────────────────────────────────────

class SiteNavConfig {
  final List<AppNavItem> navItems;
  final String ctaLabel;
  final IconData profileIcon;
  final String profileTooltip;
  const SiteNavConfig({
    required this.navItems,
    required this.ctaLabel,
    this.profileIcon    = Icons.person_outline,
    this.profileTooltip = 'Sign in or create an account',
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

/// [eyebrow] → [heading] → [subheading] → stats row
class SiteStatsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SiteStat> stats;
  const SiteStatsConfig({
    required this.eyebrow,
    required this.heading,
    required this.subheading,
    required this.stats,
  });
}

/// [eyebrow] → [heading] → [subheading] → numbered step cards
class SiteHowItWorksConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SiteStep> steps;
  const SiteHowItWorksConfig({
    required this.eyebrow,
    required this.heading,
    required this.subheading,
    required this.steps,
  });
}

/// [eyebrow] → [heading] → [subheading] → feature grid
class SiteFeaturesConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SiteFeature> features;
  const SiteFeaturesConfig({
    required this.eyebrow,
    required this.heading,
    required this.subheading,
    required this.features,
  });
}

/// [eyebrow] → [heading] → [subheading] → testimonial cards
class SiteTestimonialsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<SiteTestimonial> testimonials;
  const SiteTestimonialsConfig({
    required this.eyebrow,
    required this.heading,
    required this.subheading,
    required this.testimonials,
  });
}

/// [eyebrow] → [heading] → [subheading] → CTA button
class SiteCtaConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final String buttonLabel;
  const SiteCtaConfig({
    required this.eyebrow,
    required this.heading,
    required this.subheading,
    required this.buttonLabel,
  });
}

class SiteFooterConfig {
  final String tagline;
  final String location;
  final List<SiteFooterColumn> columns;
  final String copyright;
  const SiteFooterConfig({
    required this.tagline,
    required this.location,
    required this.columns,
    required this.copyright,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SiteConfig — master configuration object
// ─────────────────────────────────────────────────────────────────────────────

class SiteConfig {
  final SiteNavConfig nav;
  final SiteHeroConfig hero;
  final SiteTrustedConfig trusted;
  final SiteStatsConfig stats;
  final SiteHowItWorksConfig howItWorks;
  final SiteFeaturesConfig features;
  final SiteTestimonialsConfig testimonials;
  final SiteCtaConfig cta;
  final SiteFooterConfig footer;

  // Routes
  final String signupRoute;
  final String loginRoute;
  final String featuresRoute;

  // Layout
  final double pageMaxWidth;
  final double pagePaddingH;

  const SiteConfig({
    required this.nav,
    required this.hero,
    required this.trusted,
    required this.stats,
    required this.howItWorks,
    required this.features,
    required this.testimonials,
    required this.cta,
    required this.footer,
    this.signupRoute  = '/signup',
    this.loginRoute   = '/login',
    this.featuresRoute = '/features',
    this.pageMaxWidth = 1100.0,
    this.pagePaddingH = 60.0,
  });
}