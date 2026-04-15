// lib/core/admin/admin_state.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// AdminState — Riverpod providers for the admin control plane
// ─────────────────────────────────────────────────────────────────────────────
//
// PROVIDERS
//   adminDraftProvider      — StateNotifier<AdminLandingDraft>
//                             Holds the current draft. Seeded from kWellPathSiteConfig.
//   adminFlagsProvider      — StateNotifier<AdminFeatureFlags>
//   adminPublishStateProvider — StateProvider<AdminPublishState>
//   effectiveSiteConfigProvider — derives SpaceSiteConfig from the draft.
//                             screen_entry_landing.dart watches this provider
//                             instead of using the const config directly.
//   isAdminPreviewProvider  — bool toggle: live (const) vs preview (draft).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_schema.dart';
import 'admin_mapper.dart';
import '../../spaces/space_site/wellpath_config.dart';
import '../../spaces/space_site/space_site_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Preview toggle
// ─────────────────────────────────────────────────────────────────────────────

/// When true, screen_entry_landing reads from the admin draft instead of the
/// published const config. Allows live preview without publishing.
final isAdminPreviewProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Draft notifier
// ─────────────────────────────────────────────────────────────────────────────

class AdminDraftNotifier extends StateNotifier<AdminLandingDraft> {
  AdminDraftNotifier()
      : super(AdminMapper.fromConfig(kWellPathSpaceSiteConfig));

  // ── Hero ──────────────────────────────────────────────────────────────────

  void updateHeroBadge(String v)             => _update(hero: state.hero.copyWith(badge: v));
  void updateHeroPhrase(int i, String v) {
    final p = [...state.hero.phrases];
    if (i < p.length) p[i] = v;
    _update(hero: state.hero.copyWith(phrases: p));
  }
  void addHeroPhrase()                        => _update(hero: state.hero.copyWith(phrases: [...state.hero.phrases, '']));
  void removeHeroPhrase(int i) {
    final p = [...state.hero.phrases]..removeAt(i);
    _update(hero: state.hero.copyWith(phrases: p));
  }
  void updateHeroSubline(String v)            => _update(hero: state.hero.copyWith(subline: v));
  void updateHeroPrimaryCtaLabel(String v)    => _update(hero: state.hero.copyWith(primaryCtaLabel: v));
  void updateHeroSecondaryCtaLabel(String v)  => _update(hero: state.hero.copyWith(secondaryCtaLabel: v));
  void updateHeroMicrocopy(String v)          => _update(hero: state.hero.copyWith(microcopy: v));

  // ── Trusted ───────────────────────────────────────────────────────────────

  void updateTrustedLabel(String v)           => _update(trusted: state.trusted.copyWith(label: v));
  void updateTrustedLogo(int i, String v) {
    final logos = [...state.trusted.logos];
    if (i < logos.length) logos[i] = v;
    _update(trusted: state.trusted.copyWith(logos: logos));
  }
  void addTrustedLogo()                       => _update(trusted: state.trusted.copyWith(logos: [...state.trusted.logos, '']));
  void removeTrustedLogo(int i) {
    final logos = [...state.trusted.logos]..removeAt(i);
    _update(trusted: state.trusted.copyWith(logos: logos));
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  void updateStatsEyebrow(String v)           => _update(stats: state.stats.copyWith(eyebrow: v));
  void updateStatsHeading(String v)           => _update(stats: state.stats.copyWith(heading: v));
  void updateStatsSubheading(String v)        => _update(stats: state.stats.copyWith(subheading: v));
  void updateStat(int i, AdminStat s) {
    final list = [...state.stats.stats]..[i] = s;
    _update(stats: state.stats.copyWith(stats: list));
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  void updateStepsEyebrow(String v)           => _update(steps: state.steps.copyWith(eyebrow: v));
  void updateStepsHeading(String v)           => _update(steps: state.steps.copyWith(heading: v));
  void updateStepsSubheading(String v)        => _update(steps: state.steps.copyWith(subheading: v));
  void updateStep(int i, AdminStep s) {
    final list = [...state.steps.steps]..[i] = s;
    _update(steps: state.steps.copyWith(steps: list));
  }

  // ── Features ──────────────────────────────────────────────────────────────

  void updateFeaturesEyebrow(String v)        => _update(features: state.features.copyWith(eyebrow: v));
  void updateFeaturesHeading(String v)        => _update(features: state.features.copyWith(heading: v));
  void updateFeaturesSubheading(String v)     => _update(features: state.features.copyWith(subheading: v));
  void updateFeatureCard(int i, AdminFeatureCard f) {
    final list = [...state.features.features]..[i] = f;
    _update(features: state.features.copyWith(features: list));
  }

  // ── Testimonials ──────────────────────────────────────────────────────────

  void updateTestimonialsEyebrow(String v)    => _update(testimonials: state.testimonials.copyWith(eyebrow: v));
  void updateTestimonialsHeading(String v)    => _update(testimonials: state.testimonials.copyWith(heading: v));
  void updateTestimonialsSubheading(String v) => _update(testimonials: state.testimonials.copyWith(subheading: v));
  void updateTestimonial(int i, AdminTestimonial t) {
    final list = [...state.testimonials.testimonials]..[i] = t;
    _update(testimonials: state.testimonials.copyWith(testimonials: list));
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  void updateCtaEyebrow(String v)             => _update(cta: state.cta.copyWith(eyebrow: v));
  void updateCtaHeading(String v)             => _update(cta: state.cta.copyWith(heading: v));
  void updateCtaSubheading(String v)          => _update(cta: state.cta.copyWith(subheading: v));
  void updateCtaButtonLabel(String v)         => _update(cta: state.cta.copyWith(buttonLabel: v));

  // ── Footer ────────────────────────────────────────────────────────────────

  void updateFooterTagline(String v)          => _update(footer: state.footer.copyWith(tagline: v));
  void updateFooterLocation(String v)         => _update(footer: state.footer.copyWith(location: v));
  void updateFooterCopyright(String v)        => _update(footer: state.footer.copyWith(copyright: v));

  // ── Nav ───────────────────────────────────────────────────────────────────

  void updateNavCtaLabel(String v)            => _update(nav: state.nav.copyWith(ctaLabel: v));
  void updateNavItem(int i, AdminNavLink l) {
    final list = [...state.nav.navItems]..[i] = l;
    _update(nav: state.nav.copyWith(navItems: list));
  }

  // ── Brand ─────────────────────────────────────────────────────────────────

  void updateBrand(AdminBrandConfig b)        => _update(brand: b);

  // ── Flags ─────────────────────────────────────────────────────────────────

  void updateFlags(AdminFeatureFlags f)       => _update(flags: f);
  void toggleFlag(AdminFeatureFlags Function(AdminFeatureFlags) updater) =>
      _update(flags: updater(state.flags));

  // ── Publish ───────────────────────────────────────────────────────────────

  void setPublishState(AdminPublishState s)   => _update(publishState: s);

  /// Reset draft to the published const config.
  void resetToPublished()                     => state = AdminMapper.fromConfig(kWellPathSpaceSiteConfig);

  // ── Internal ──────────────────────────────────────────────────────────────

  void _update({
    AdminHeroConfig?         hero,
    AdminTrustedConfig?      trusted,
    AdminStatsConfig?        stats,
    AdminStepsConfig?        steps,
    AdminFeaturesConfig?     features,
    AdminTestimonialsConfig? testimonials,
    AdminCtaConfig?          cta,
    AdminFooterConfig?       footer,
    AdminNavConfig?          nav,
    AdminBrandConfig?        brand,
    AdminFeatureFlags?       flags,
    AdminPublishState?       publishState,
  }) {
    state = state.copyWith(
      hero:           hero,
      trusted:        trusted,
      stats:          stats,
      steps:          steps,
      features:       features,
      testimonials:   testimonials,
      cta:            cta,
      footer:         footer,
      nav:            nav,
      brand:          brand,
      flags:          flags,
      publishState:   publishState ?? AdminPublishState.draft,
      lastModified:   DateTime.now(),
      lastModifiedBy: 'admin',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final adminDraftProvider =
    StateNotifierProvider<AdminDraftNotifier, AdminLandingDraft>(
        (ref) => AdminDraftNotifier());

/// The SpaceSiteConfig derived from the current draft.
/// screen_entry_landing.dart watches this for live preview.
final effectiveSiteConfigProvider = Provider<SpaceSiteConfig>((ref) {
  final isPreview = ref.watch(isAdminPreviewProvider);
  if (!isPreview) return kWellPathSpaceSiteConfig;
  final draft = ref.watch(adminDraftProvider);
  return AdminMapper.toConfig(draft, kWellPathSpaceSiteConfig);
});

/// The AdminFeatureFlags from the current draft.
final effectiveFlagsProvider = Provider<AdminFeatureFlags>((ref) {
  final isPreview = ref.watch(isAdminPreviewProvider);
  if (!isPreview) return const AdminFeatureFlags();
  return ref.watch(adminDraftProvider).flags;
});