// lib/core/admin/admin_mapper.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// AdminMapper — Converts between AdminLandingDraft and SpaceSiteConfig
// ─────────────────────────────────────────────────────────────────────────────
//
// Two directions:
//   fromConfig(SpaceSiteConfig) → AdminLandingDraft   (seed draft from const)
//   toConfig(AdminLandingDraft) → SpaceSiteConfig      (draft → live config)
//
// Manifest path registry (directive §7):
//   space_site.screen_home.section_core.hero.badge
//   space_site.screen_home.section_core.hero.phrases[n]
//   space_site.screen_home.section_core.hero.subline
//   space_site.screen_home.section_core.hero.primaryCtaLabel
//   space_site.screen_home.section_core.hero.secondaryCtaLabel
//   space_site.screen_home.section_core.hero.microcopy
//   space_site.screen_home.section_core.trust.label
//   space_site.screen_home.section_core.trust.logos[n]
//   space_site.screen_home.section_context.stats.eyebrow
//   space_site.screen_home.section_context.stats.heading
//   space_site.screen_home.section_context.stats.subheading
//   space_site.screen_home.section_context.stats.items[n].*
//   space_site.screen_home.section_context.steps.eyebrow  (+ heading, subheading, items)
//   space_site.screen_home.section_context.features.*
//   space_site.screen_home.section_context.testimonials.*
//   space_site.screen_home.section_connect.cta.*
//   space_site.screen_home.section_connect.footer.*
//   space_site.screen_home.nav.*
//   space_site.brand.*
//   space_site.screen_home.flags.*
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'admin_schema.dart';

// Import the site config — path will match your project after rename
import '../../spaces/space_site/space_site_config.dart';
import '../../core/navigation/nav_items.dart';
import '../../core/style/app_motion.dart';
import '../../core/style/app_branding.dart';

abstract class AdminMapper {

  // ─────────────────────────────────────────────────────────────────────────
  // fromConfig — seed a draft from the published const config
  // ─────────────────────────────────────────────────────────────────────────

  static AdminLandingDraft fromConfig(SpaceSiteConfig c) {
    return AdminLandingDraft(
      hero: AdminHeroConfig(
        badge:             c.hero.badge,
        phrases:           List<String>.from(c.hero.headline.phrases),
        subline:           c.hero.subline,
        primaryCtaLabel:   c.hero.primaryCtaLabel,
        secondaryCtaLabel: c.hero.secondaryCtaLabel,
        microcopy:         c.hero.microcopy,
      ),

      trusted: AdminTrustedConfig(
        label: c.trusted.label,
        logos: List<String>.from(c.trusted.logos),
      ),

      stats: AdminStatsConfig(
        eyebrow:    c.stats.eyebrow,
        heading:    c.stats.heading,
        subheading: c.stats.subheading,
        stats: c.stats.stats.map((s) => AdminStat(
          display:      s.display,
          numericValue: s.numericValue,
          suffix:       s.suffix,
          label:        s.label,
        )).toList(),
      ),

      steps: AdminStepsConfig(
        eyebrow:    c.steps.eyebrow,
        heading:    c.steps.heading,
        subheading: c.steps.subheading,
        steps: c.steps.steps.map((s) => AdminStep(
          number:        s.number,
          title:         s.title,
          body:          s.body,
          iconCodePoint: s.icon.codePoint,
        )).toList(),
      ),

      features: AdminFeaturesConfig(
        eyebrow:    c.features.eyebrow,
        heading:    c.features.heading,
        subheading: c.features.subheading,
        features: c.features.features.map((f) => AdminFeatureCard(
          title:              f.title,
          body:               f.body,
          iconCodePoint:      f.icon.codePoint,
          useSecondaryAccent: f.useSecondaryAccent,
        )).toList(),
      ),

      testimonials: AdminTestimonialsConfig(
        eyebrow:    c.testimonials.eyebrow,
        heading:    c.testimonials.heading,
        subheading: c.testimonials.subheading,
        testimonials: c.testimonials.testimonials.map((t) => AdminTestimonial(
          quote:    t.quote,
          name:     t.name,
          location: t.location,
          initials: t.initials,
        )).toList(),
      ),

      cta: AdminCtaConfig(
        eyebrow:     c.cta.eyebrow,
        heading:     c.cta.heading,
        subheading:  c.cta.subheading,
        buttonLabel: c.cta.buttonLabel,
      ),

      footer: AdminFooterConfig(
        tagline:   c.footer.tagline,
        location:  c.footer.location,
        copyright: c.footer.copyright,
        columns: c.footer.columns.map((col) => AdminFooterColumn(
          title: col.title,
          links: col.links.map((l) =>
              AdminFooterLink(label: l.label, route: l.route)).toList(),
        )).toList(),
      ),

      nav: AdminNavConfig(
        ctaLabel: c.nav.ctaLabel,
        navItems: c.nav.navItems.map((n) =>
            AdminNavLink(label: n.label, route: n.route)).toList(),
      ),

      brand: AdminBrandConfig(
        primaryHex:   AdminBrandConfig.colorToHex(BrandColors.primary),
        secondaryHex: AdminBrandConfig.colorToHex(BrandColors.secondary),
        tertiaryHex:  AdminBrandConfig.colorToHex(BrandColors.tertiary),
        appName:      BrandCopy.appName,
        tagline:      BrandCopy.tagline,
        domain:       BrandCopy.domain,
        copyright:    BrandCopy.copyright,
      ),

      flags:          const AdminFeatureFlags(),
      publishState:   AdminPublishState.draft,
      lastModified:   DateTime.now(),
      lastModifiedBy: 'system',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // toConfig — convert a draft back to a SpaceSiteConfig for live rendering
  // ─────────────────────────────────────────────────────────────────────────

  static SpaceSiteConfig toConfig(AdminLandingDraft d, SpaceSiteConfig base) {
    return SpaceSiteConfig(
      signupRoute:   base.signupRoute,
      loginRoute:    base.loginRoute,
      featuresRoute: base.featuresRoute,
      pageMaxWidth:  base.pageMaxWidth,
      pagePaddingH:  base.pagePaddingH,

      nav: SpaceSiteNavConfig(
        ctaLabel: d.nav.ctaLabel,
        navItems: d.nav.navItems.map((n) =>
            MarketingNavItem(label: n.label, route: n.route)).toList(),
      ),

      hero: SiteHeroConfig(
        badge:             d.hero.badge,
        headline: TypingTextConfig(
          phrases:           d.hero.phrases,
          headlineBlockHeight: 120,
        ),
        subline:           d.hero.subline,
        primaryCtaLabel:   d.hero.primaryCtaLabel,
        secondaryCtaLabel: d.hero.secondaryCtaLabel,
        microcopy:         d.hero.microcopy,
      ),

      trusted: SiteTrustedConfig(
        label: d.trusted.label,
        logos: d.trusted.logos,
      ),

      stats: SiteStatsConfig(
        eyebrow:    d.stats.eyebrow,
        heading:    d.stats.heading,
        subheading: d.stats.subheading,
        stats: d.stats.stats.map((s) => SpaceSiteStat(
          display:      s.display,
          numericValue: s.numericValue,
          suffix:       s.suffix,
          label:        s.label,
        )).toList(),
      ),

      steps: SiteStepsConfig(
        eyebrow:    d.steps.eyebrow,
        heading:    d.steps.heading,
        subheading: d.steps.subheading,
        steps: d.steps.steps.map((s) => SpaceSiteStep(
          number: s.number,
          title:  s.title,
          body:   s.body,
          icon:   IconData(s.iconCodePoint, fontFamily: 'MaterialIcons'),
        )).toList(),
      ),

      features: SiteFeaturesConfig(
        eyebrow:    d.features.eyebrow,
        heading:    d.features.heading,
        subheading: d.features.subheading,
        features: d.features.features.map((f) => SpaceSiteFeature(
          title:              f.title,
          body:               f.body,
          icon:               IconData(f.iconCodePoint, fontFamily: 'MaterialIcons'),
          useSecondaryAccent: f.useSecondaryAccent,
        )).toList(),
      ),

      testimonials: SiteTestimonialsConfig(
        eyebrow:    d.testimonials.eyebrow,
        heading:    d.testimonials.heading,
        subheading: d.testimonials.subheading,
        testimonials: d.testimonials.testimonials.map((t) => SpaceSiteTestimonial(
          quote:    t.quote,
          name:     t.name,
          location: t.location,
          initials: t.initials,
        )).toList(),
      ),

      cta: SiteCtaConfig(
        eyebrow:     d.cta.eyebrow,
        heading:     d.cta.heading,
        subheading:  d.cta.subheading,
        buttonLabel: d.cta.buttonLabel,
      ),

      footer: SiteFooterConfig(
        tagline:   d.footer.tagline,
        location:  d.footer.location,
        copyright: d.footer.copyright,
        columns: d.footer.columns.map((col) => SpaceSiteFooterColumn(
          title: col.title,
          links: col.links.map((l) =>
              SpaceSiteFooterLink(label: l.label, route: l.route)).toList(),
        )).toList(),
      ),
    );
  }
}