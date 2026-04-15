// lib/core/admin/admin_schema.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// AdminSchema — WellPath Admin Data Models
// ─────────────────────────────────────────────────────────────────────────────
//
// DESIGN PRINCIPLE (from directive §7)
//   Every editable field maps to a stable manifest path:
//     space_site.screen_home.section_core.hero.badge
//     space_site.screen_home.section_context.steps[0].title
//     space_site.brand.colors.primary
//
//   These classes are the mutable, JSON-serialisable mirror of SpaceSiteConfig.
//   Admin UI reads/writes these. The merge engine converts them to live config.
//
// LAYERS
//   AdminLandingDraft  — full mutable landing page config (content + features)
//   AdminBrandDraft    — brand tokens (colors, fonts, identity)
//   AdminFeatureFlags  — boolean section/feature toggles
//   AdminPublishState  — draft / published / validating / error
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminPublishState
// ─────────────────────────────────────────────────────────────────────────────

enum AdminPublishState { draft, publishing, published, error }

// ─────────────────────────────────────────────────────────────────────────────
// AdminPermissionLevel
// ─────────────────────────────────────────────────────────────────────────────

/// Three permission tiers as per directive §9.
/// client   — copy, assets, approved feature flags.
/// developer — deeper structural mappings, field unlocks.
/// architect — schema-level rules, canonical defaults, permission editing.
enum AdminPermissionLevel { client, developer, architect }

// ─────────────────────────────────────────────────────────────────────────────
// AdminValidationResult
// ─────────────────────────────────────────────────────────────────────────────

class AdminValidationResult {
  final bool isValid;
  final List<AdminValidationError> errors;
  final List<AdminValidationWarning> warnings;

  const AdminValidationResult({
    required this.isValid,
    this.errors   = const [],
    this.warnings = const [],
  });

  static const valid = AdminValidationResult(isValid: true);
}

class AdminValidationError {
  final String fieldPath;
  final String message;
  const AdminValidationError({required this.fieldPath, required this.message});
}

class AdminValidationWarning {
  final String fieldPath;
  final String message;
  const AdminValidationWarning({required this.fieldPath, required this.message});
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// path: space_site.screen_home.section_core.hero.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminHeroConfig {
  final String badge;
  /// Typing animation phrases. Index 0 is the static fallback.
  final List<String> phrases;
  final String subline;
  final String primaryCtaLabel;
  final String secondaryCtaLabel;
  final String microcopy;

  const AdminHeroConfig({
    required this.badge,
    required this.phrases,
    required this.subline,
    required this.primaryCtaLabel,
    required this.secondaryCtaLabel,
    required this.microcopy,
  });

  AdminHeroConfig copyWith({
    String? badge, List<String>? phrases, String? subline,
    String? primaryCtaLabel, String? secondaryCtaLabel, String? microcopy,
  }) => AdminHeroConfig(
    badge:             badge             ?? this.badge,
    phrases:           phrases           ?? this.phrases,
    subline:           subline           ?? this.subline,
    primaryCtaLabel:   primaryCtaLabel   ?? this.primaryCtaLabel,
    secondaryCtaLabel: secondaryCtaLabel ?? this.secondaryCtaLabel,
    microcopy:         microcopy         ?? this.microcopy,
  );

  factory AdminHeroConfig.fromJson(Map<String, dynamic> j) => AdminHeroConfig(
    badge:             j['badge']             as String,
    phrases:           List<String>.from(j['phrases'] as List),
    subline:           j['subline']           as String,
    primaryCtaLabel:   j['primaryCtaLabel']   as String,
    secondaryCtaLabel: j['secondaryCtaLabel'] as String,
    microcopy:         j['microcopy']         as String,
  );

  Map<String, dynamic> toJson() => {
    'badge':             badge,
    'phrases':           phrases,
    'subline':           subline,
    'primaryCtaLabel':   primaryCtaLabel,
    'secondaryCtaLabel': secondaryCtaLabel,
    'microcopy':         microcopy,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// TRUSTED STRIP
// path: space_site.screen_home.section_core.trust.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminTrustedConfig {
  final String label;
  final List<String> logos;

  const AdminTrustedConfig({required this.label, required this.logos});

  AdminTrustedConfig copyWith({String? label, List<String>? logos}) =>
      AdminTrustedConfig(label: label ?? this.label, logos: logos ?? this.logos);

  factory AdminTrustedConfig.fromJson(Map<String, dynamic> j) =>
      AdminTrustedConfig(
        label: j['label'] as String,
        logos: List<String>.from(j['logos'] as List),
      );

  Map<String, dynamic> toJson() => {'label': label, 'logos': logos};
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS
// path: space_site.screen_home.section_context.stats.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminStat {
  final String display;
  final int numericValue;
  final String suffix;
  final String label;

  const AdminStat({
    required this.display, required this.numericValue,
    required this.suffix,  required this.label,
  });

  AdminStat copyWith({String? display, int? numericValue, String? suffix, String? label}) =>
      AdminStat(
        display:      display      ?? this.display,
        numericValue: numericValue ?? this.numericValue,
        suffix:       suffix       ?? this.suffix,
        label:        label        ?? this.label,
      );

  factory AdminStat.fromJson(Map<String, dynamic> j) => AdminStat(
    display:      j['display']      as String,
    numericValue: j['numericValue'] as int,
    suffix:       j['suffix']       as String,
    label:        j['label']        as String,
  );
  Map<String, dynamic> toJson() => {
    'display': display, 'numericValue': numericValue,
    'suffix': suffix,   'label': label,
  };
}

class AdminStatsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<AdminStat> stats;

  const AdminStatsConfig({
    required this.eyebrow, required this.heading,
    required this.subheading, required this.stats,
  });

  AdminStatsConfig copyWith({
    String? eyebrow, String? heading, String? subheading, List<AdminStat>? stats,
  }) => AdminStatsConfig(
    eyebrow:    eyebrow    ?? this.eyebrow,
    heading:    heading    ?? this.heading,
    subheading: subheading ?? this.subheading,
    stats:      stats      ?? this.stats,
  );

  factory AdminStatsConfig.fromJson(Map<String, dynamic> j) => AdminStatsConfig(
    eyebrow:    j['eyebrow']    as String,
    heading:    j['heading']    as String,
    subheading: j['subheading'] as String,
    stats: (j['stats'] as List).map((e) => AdminStat.fromJson(e as Map<String,dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'eyebrow': eyebrow, 'heading': heading, 'subheading': subheading,
    'stats': stats.map((s) => s.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// STEPS  (formerly howItWorks)
// path: space_site.screen_home.section_context.steps.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminStep {
  final String number;
  final String title;
  final String body;
  /// Icon code point (e.g. Icons.search_rounded.codePoint)
  final int iconCodePoint;

  const AdminStep({
    required this.number, required this.title,
    required this.body,   required this.iconCodePoint,
  });

  AdminStep copyWith({String? number, String? title, String? body, int? iconCodePoint}) =>
      AdminStep(
        number:        number        ?? this.number,
        title:         title         ?? this.title,
        body:          body          ?? this.body,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      );

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  factory AdminStep.fromJson(Map<String, dynamic> j) => AdminStep(
    number:        j['number']        as String,
    title:         j['title']         as String,
    body:          j['body']          as String,
    iconCodePoint: j['iconCodePoint'] as int,
  );
  Map<String, dynamic> toJson() => {
    'number': number, 'title': title, 'body': body,
    'iconCodePoint': iconCodePoint,
  };
}

class AdminStepsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<AdminStep> steps;

  const AdminStepsConfig({
    required this.eyebrow, required this.heading,
    required this.subheading, required this.steps,
  });

  AdminStepsConfig copyWith({
    String? eyebrow, String? heading, String? subheading, List<AdminStep>? steps,
  }) => AdminStepsConfig(
    eyebrow:    eyebrow    ?? this.eyebrow,
    heading:    heading    ?? this.heading,
    subheading: subheading ?? this.subheading,
    steps:      steps      ?? this.steps,
  );

  factory AdminStepsConfig.fromJson(Map<String, dynamic> j) => AdminStepsConfig(
    eyebrow:    j['eyebrow']    as String,
    heading:    j['heading']    as String,
    subheading: j['subheading'] as String,
    steps: (j['steps'] as List).map((e) => AdminStep.fromJson(e as Map<String,dynamic>)).toList(),
  );
  Map<String, dynamic> toJson() => {
    'eyebrow': eyebrow, 'heading': heading, 'subheading': subheading,
    'steps': steps.map((s) => s.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURES
// path: space_site.screen_home.section_context.features.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminFeatureCard {
  final String title;
  final String body;
  final int iconCodePoint;
  final bool useSecondaryAccent;

  const AdminFeatureCard({
    required this.title,  required this.body,
    required this.iconCodePoint, this.useSecondaryAccent = false,
  });

  AdminFeatureCard copyWith({
    String? title, String? body, int? iconCodePoint, bool? useSecondaryAccent,
  }) => AdminFeatureCard(
    title:              title              ?? this.title,
    body:               body               ?? this.body,
    iconCodePoint:      iconCodePoint      ?? this.iconCodePoint,
    useSecondaryAccent: useSecondaryAccent ?? this.useSecondaryAccent,
  );

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  factory AdminFeatureCard.fromJson(Map<String, dynamic> j) => AdminFeatureCard(
    title:              j['title']              as String,
    body:               j['body']               as String,
    iconCodePoint:      j['iconCodePoint']      as int,
    useSecondaryAccent: j['useSecondaryAccent'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'title': title, 'body': body,
    'iconCodePoint': iconCodePoint, 'useSecondaryAccent': useSecondaryAccent,
  };
}

class AdminFeaturesConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<AdminFeatureCard> features;

  const AdminFeaturesConfig({
    required this.eyebrow, required this.heading,
    required this.subheading, required this.features,
  });

  AdminFeaturesConfig copyWith({
    String? eyebrow, String? heading, String? subheading, List<AdminFeatureCard>? features,
  }) => AdminFeaturesConfig(
    eyebrow:    eyebrow    ?? this.eyebrow,
    heading:    heading    ?? this.heading,
    subheading: subheading ?? this.subheading,
    features:   features   ?? this.features,
  );

  factory AdminFeaturesConfig.fromJson(Map<String, dynamic> j) => AdminFeaturesConfig(
    eyebrow:    j['eyebrow']    as String,
    heading:    j['heading']    as String,
    subheading: j['subheading'] as String,
    features: (j['features'] as List)
        .map((e) => AdminFeatureCard.fromJson(e as Map<String,dynamic>)).toList(),
  );
  Map<String, dynamic> toJson() => {
    'eyebrow': eyebrow, 'heading': heading, 'subheading': subheading,
    'features': features.map((f) => f.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTIMONIALS
// path: space_site.screen_home.section_context.testimonials.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminTestimonial {
  final String quote;
  final String name;
  final String location;
  final String initials;

  const AdminTestimonial({
    required this.quote, required this.name,
    required this.location, required this.initials,
  });

  AdminTestimonial copyWith({
    String? quote, String? name, String? location, String? initials,
  }) => AdminTestimonial(
    quote:    quote    ?? this.quote,
    name:     name     ?? this.name,
    location: location ?? this.location,
    initials: initials ?? this.initials,
  );

  factory AdminTestimonial.fromJson(Map<String, dynamic> j) => AdminTestimonial(
    quote:    j['quote']    as String,
    name:     j['name']     as String,
    location: j['location'] as String,
    initials: j['initials'] as String,
  );
  Map<String, dynamic> toJson() =>
      {'quote': quote, 'name': name, 'location': location, 'initials': initials};
}

class AdminTestimonialsConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final List<AdminTestimonial> testimonials;

  const AdminTestimonialsConfig({
    required this.eyebrow, required this.heading,
    required this.subheading, required this.testimonials,
  });

  AdminTestimonialsConfig copyWith({
    String? eyebrow, String? heading, String? subheading,
    List<AdminTestimonial>? testimonials,
  }) => AdminTestimonialsConfig(
    eyebrow:      eyebrow      ?? this.eyebrow,
    heading:      heading      ?? this.heading,
    subheading:   subheading   ?? this.subheading,
    testimonials: testimonials ?? this.testimonials,
  );

  factory AdminTestimonialsConfig.fromJson(Map<String, dynamic> j) => AdminTestimonialsConfig(
    eyebrow:    j['eyebrow']    as String,
    heading:    j['heading']    as String,
    subheading: j['subheading'] as String,
    testimonials: (j['testimonials'] as List)
        .map((e) => AdminTestimonial.fromJson(e as Map<String,dynamic>)).toList(),
  );
  Map<String, dynamic> toJson() => {
    'eyebrow': eyebrow, 'heading': heading, 'subheading': subheading,
    'testimonials': testimonials.map((t) => t.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA BANNER
// path: space_site.screen_home.section_connect.cta.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminCtaConfig {
  final String eyebrow;
  final String heading;
  final String subheading;
  final String buttonLabel;

  const AdminCtaConfig({
    required this.eyebrow, required this.heading,
    required this.subheading, required this.buttonLabel,
  });

  AdminCtaConfig copyWith({
    String? eyebrow, String? heading, String? subheading, String? buttonLabel,
  }) => AdminCtaConfig(
    eyebrow:     eyebrow     ?? this.eyebrow,
    heading:     heading     ?? this.heading,
    subheading:  subheading  ?? this.subheading,
    buttonLabel: buttonLabel ?? this.buttonLabel,
  );

  factory AdminCtaConfig.fromJson(Map<String, dynamic> j) => AdminCtaConfig(
    eyebrow:     j['eyebrow']     as String,
    heading:     j['heading']     as String,
    subheading:  j['subheading']  as String,
    buttonLabel: j['buttonLabel'] as String,
  );
  Map<String, dynamic> toJson() => {
    'eyebrow': eyebrow, 'heading': heading,
    'subheading': subheading, 'buttonLabel': buttonLabel,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// path: space_site.screen_home.section_connect.footer.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminFooterLink {
  final String label;
  final String route;
  const AdminFooterLink({required this.label, required this.route});

  AdminFooterLink copyWith({String? label, String? route}) =>
      AdminFooterLink(label: label ?? this.label, route: route ?? this.route);

  factory AdminFooterLink.fromJson(Map<String, dynamic> j) =>
      AdminFooterLink(label: j['label'] as String, route: j['route'] as String);
  Map<String, dynamic> toJson() => {'label': label, 'route': route};
}

class AdminFooterColumn {
  final String title;
  final List<AdminFooterLink> links;
  const AdminFooterColumn({required this.title, required this.links});

  AdminFooterColumn copyWith({String? title, List<AdminFooterLink>? links}) =>
      AdminFooterColumn(title: title ?? this.title, links: links ?? this.links);

  factory AdminFooterColumn.fromJson(Map<String, dynamic> j) => AdminFooterColumn(
    title: j['title'] as String,
    links: (j['links'] as List)
        .map((e) => AdminFooterLink.fromJson(e as Map<String,dynamic>)).toList(),
  );
  Map<String, dynamic> toJson() =>
      {'title': title, 'links': links.map((l) => l.toJson()).toList()};
}

class AdminFooterConfig {
  final String tagline;
  final String location;
  final String copyright;
  final List<AdminFooterColumn> columns;

  const AdminFooterConfig({
    required this.tagline, required this.location,
    required this.copyright, required this.columns,
  });

  AdminFooterConfig copyWith({
    String? tagline, String? location, String? copyright,
    List<AdminFooterColumn>? columns,
  }) => AdminFooterConfig(
    tagline:   tagline   ?? this.tagline,
    location:  location  ?? this.location,
    copyright: copyright ?? this.copyright,
    columns:   columns   ?? this.columns,
  );

  factory AdminFooterConfig.fromJson(Map<String, dynamic> j) => AdminFooterConfig(
    tagline:   j['tagline']   as String,
    location:  j['location']  as String,
    copyright: j['copyright'] as String,
    columns: (j['columns'] as List)
        .map((e) => AdminFooterColumn.fromJson(e as Map<String,dynamic>)).toList(),
  );
  Map<String, dynamic> toJson() => {
    'tagline': tagline, 'location': location, 'copyright': copyright,
    'columns': columns.map((c) => c.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV
// path: space_site.screen_home.nav.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminNavLink {
  final String label;
  final String route;
  const AdminNavLink({required this.label, required this.route});
  AdminNavLink copyWith({String? label, String? route}) =>
      AdminNavLink(label: label ?? this.label, route: route ?? this.route);
  factory AdminNavLink.fromJson(Map<String, dynamic> j) =>
      AdminNavLink(label: j['label'] as String, route: j['route'] as String);
  Map<String, dynamic> toJson() => {'label': label, 'route': route};
}

class AdminNavConfig {
  final List<AdminNavLink> navItems;
  final String ctaLabel;
  const AdminNavConfig({required this.navItems, required this.ctaLabel});

  AdminNavConfig copyWith({List<AdminNavLink>? navItems, String? ctaLabel}) =>
      AdminNavConfig(
        navItems: navItems ?? this.navItems,
        ctaLabel: ctaLabel ?? this.ctaLabel,
      );

  factory AdminNavConfig.fromJson(Map<String, dynamic> j) => AdminNavConfig(
    navItems: (j['navItems'] as List)
        .map((e) => AdminNavLink.fromJson(e as Map<String,dynamic>)).toList(),
    ctaLabel: j['ctaLabel'] as String,
  );
  Map<String, dynamic> toJson() =>
      {'navItems': navItems.map((n) => n.toJson()).toList(), 'ctaLabel': ctaLabel};
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND
// path: space_site.brand.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminBrandConfig {
  /// Hex string e.g. "#00CC66"
  final String primaryHex;
  final String secondaryHex;
  final String tertiaryHex;
  final String appName;
  final String tagline;
  final String domain;
  final String copyright;

  const AdminBrandConfig({
    required this.primaryHex,
    required this.secondaryHex,
    required this.tertiaryHex,
    required this.appName,
    required this.tagline,
    required this.domain,
    required this.copyright,
  });

  Color get primaryColor   => _hexToColor(primaryHex);
  Color get secondaryColor => _hexToColor(secondaryHex);
  Color get tertiaryColor  => _hexToColor(tertiaryHex);

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    return Color(int.parse(h, radix: 16));
  }

  static String colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  AdminBrandConfig copyWith({
    String? primaryHex, String? secondaryHex, String? tertiaryHex,
    String? appName, String? tagline, String? domain, String? copyright,
  }) => AdminBrandConfig(
    primaryHex:   primaryHex   ?? this.primaryHex,
    secondaryHex: secondaryHex ?? this.secondaryHex,
    tertiaryHex:  tertiaryHex  ?? this.tertiaryHex,
    appName:      appName      ?? this.appName,
    tagline:      tagline      ?? this.tagline,
    domain:       domain       ?? this.domain,
    copyright:    copyright    ?? this.copyright,
  );

  factory AdminBrandConfig.fromJson(Map<String, dynamic> j) => AdminBrandConfig(
    primaryHex:   j['primaryHex']   as String,
    secondaryHex: j['secondaryHex'] as String,
    tertiaryHex:  j['tertiaryHex']  as String,
    appName:      j['appName']      as String,
    tagline:      j['tagline']      as String,
    domain:       j['domain']       as String,
    copyright:    j['copyright']    as String,
  );
  Map<String, dynamic> toJson() => {
    'primaryHex': primaryHex, 'secondaryHex': secondaryHex, 'tertiaryHex': tertiaryHex,
    'appName': appName, 'tagline': tagline, 'domain': domain, 'copyright': copyright,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE FLAGS
// path: space_site.screen_home.features.*
// ─────────────────────────────────────────────────────────────────────────────

class AdminFeatureFlags {
  // Section visibility
  final bool showTrustedStrip;
  final bool showStats;
  final bool showSteps;
  final bool showFeatureCards;
  final bool showTestimonials;
  final bool showCtaBanner;
  final bool showFab;

  // Motion
  final bool enableParallax;
  final bool enableDepthMesh;
  final bool enableTypingAnimation;
  final bool enableCardBorderAnimation;
  final bool enableAttentionButton;

  // Hero animation
  final bool showHeroAnimationOnPageHero;
  final bool showHeroAnimationOnAbout;
  final bool showHeroAnimationOnFeatures;
  final bool showHeroAnimationOnPricing;

  const AdminFeatureFlags({
    this.showTrustedStrip               = true,
    this.showStats                      = true,
    this.showSteps                      = true,
    this.showFeatureCards               = true,
    this.showTestimonials               = true,
    this.showCtaBanner                  = true,
    this.showFab                        = true,
    this.enableParallax                 = true,
    this.enableDepthMesh                = true,
    this.enableTypingAnimation          = true,
    this.enableCardBorderAnimation      = true,
    this.enableAttentionButton          = true,
    this.showHeroAnimationOnPageHero    = true,
    this.showHeroAnimationOnAbout       = true,
    this.showHeroAnimationOnFeatures    = true,
    this.showHeroAnimationOnPricing     = true,
  });

  AdminFeatureFlags copyWith({
    bool? showTrustedStrip,  bool? showStats,     bool? showSteps,
    bool? showFeatureCards,  bool? showTestimonials, bool? showCtaBanner,
    bool? showFab,           bool? enableParallax, bool? enableDepthMesh,
    bool? enableTypingAnimation,   bool? enableCardBorderAnimation,
    bool? enableAttentionButton,
    bool? showHeroAnimationOnPageHero, bool? showHeroAnimationOnAbout,
    bool? showHeroAnimationOnFeatures, bool? showHeroAnimationOnPricing,
  }) => AdminFeatureFlags(
    showTrustedStrip:              showTrustedStrip              ?? this.showTrustedStrip,
    showStats:                     showStats                     ?? this.showStats,
    showSteps:                     showSteps                     ?? this.showSteps,
    showFeatureCards:              showFeatureCards              ?? this.showFeatureCards,
    showTestimonials:              showTestimonials              ?? this.showTestimonials,
    showCtaBanner:                 showCtaBanner                 ?? this.showCtaBanner,
    showFab:                       showFab                       ?? this.showFab,
    enableParallax:                enableParallax                ?? this.enableParallax,
    enableDepthMesh:               enableDepthMesh               ?? this.enableDepthMesh,
    enableTypingAnimation:         enableTypingAnimation         ?? this.enableTypingAnimation,
    enableCardBorderAnimation:     enableCardBorderAnimation     ?? this.enableCardBorderAnimation,
    enableAttentionButton:         enableAttentionButton         ?? this.enableAttentionButton,
    showHeroAnimationOnPageHero:   showHeroAnimationOnPageHero   ?? this.showHeroAnimationOnPageHero,
    showHeroAnimationOnAbout:      showHeroAnimationOnAbout      ?? this.showHeroAnimationOnAbout,
    showHeroAnimationOnFeatures:   showHeroAnimationOnFeatures   ?? this.showHeroAnimationOnFeatures,
    showHeroAnimationOnPricing:    showHeroAnimationOnPricing    ?? this.showHeroAnimationOnPricing,
  );

  factory AdminFeatureFlags.fromJson(Map<String, dynamic> j) => AdminFeatureFlags(
    showTrustedStrip:              j['showTrustedStrip']              as bool? ?? true,
    showStats:                     j['showStats']                     as bool? ?? true,
    showSteps:                     j['showSteps']                     as bool? ?? true,
    showFeatureCards:              j['showFeatureCards']              as bool? ?? true,
    showTestimonials:              j['showTestimonials']              as bool? ?? true,
    showCtaBanner:                 j['showCtaBanner']                 as bool? ?? true,
    showFab:                       j['showFab']                       as bool? ?? true,
    enableParallax:                j['enableParallax']                as bool? ?? true,
    enableDepthMesh:               j['enableDepthMesh']               as bool? ?? true,
    enableTypingAnimation:         j['enableTypingAnimation']         as bool? ?? true,
    enableCardBorderAnimation:     j['enableCardBorderAnimation']     as bool? ?? true,
    enableAttentionButton:         j['enableAttentionButton']         as bool? ?? true,
    showHeroAnimationOnPageHero:   j['showHeroAnimationOnPageHero']   as bool? ?? true,
    showHeroAnimationOnAbout:      j['showHeroAnimationOnAbout']      as bool? ?? true,
    showHeroAnimationOnFeatures:   j['showHeroAnimationOnFeatures']   as bool? ?? true,
    showHeroAnimationOnPricing:    j['showHeroAnimationOnPricing']    as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'showTrustedStrip':              showTrustedStrip,
    'showStats':                     showStats,
    'showSteps':                     showSteps,
    'showFeatureCards':              showFeatureCards,
    'showTestimonials':              showTestimonials,
    'showCtaBanner':                 showCtaBanner,
    'showFab':                       showFab,
    'enableParallax':                enableParallax,
    'enableDepthMesh':               enableDepthMesh,
    'enableTypingAnimation':         enableTypingAnimation,
    'enableCardBorderAnimation':     enableCardBorderAnimation,
    'enableAttentionButton':         enableAttentionButton,
    'showHeroAnimationOnPageHero':   showHeroAnimationOnPageHero,
    'showHeroAnimationOnAbout':      showHeroAnimationOnAbout,
    'showHeroAnimationOnFeatures':   showHeroAnimationOnFeatures,
    'showHeroAnimationOnPricing':    showHeroAnimationOnPricing,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminLandingDraft — the full mutable draft for the landing page
// ─────────────────────────────────────────────────────────────────────────────

class AdminLandingDraft {
  final AdminHeroConfig          hero;
  final AdminTrustedConfig       trusted;
  final AdminStatsConfig         stats;
  final AdminStepsConfig         steps;
  final AdminFeaturesConfig      features;
  final AdminTestimonialsConfig  testimonials;
  final AdminCtaConfig           cta;
  final AdminFooterConfig        footer;
  final AdminNavConfig           nav;
  final AdminBrandConfig         brand;
  final AdminFeatureFlags        flags;
  final AdminPublishState        publishState;
  final DateTime                 lastModified;
  final String                   lastModifiedBy;

  const AdminLandingDraft({
    required this.hero,
    required this.trusted,
    required this.stats,
    required this.steps,
    required this.features,
    required this.testimonials,
    required this.cta,
    required this.footer,
    required this.nav,
    required this.brand,
    required this.flags,
    required this.publishState,
    required this.lastModified,
    required this.lastModifiedBy,
  });

  AdminLandingDraft copyWith({
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
    DateTime?                lastModified,
    String?                  lastModifiedBy,
  }) => AdminLandingDraft(
    hero:           hero           ?? this.hero,
    trusted:        trusted        ?? this.trusted,
    stats:          stats          ?? this.stats,
    steps:          steps          ?? this.steps,
    features:       features       ?? this.features,
    testimonials:   testimonials   ?? this.testimonials,
    cta:            cta            ?? this.cta,
    footer:         footer         ?? this.footer,
    nav:            nav            ?? this.nav,
    brand:          brand          ?? this.brand,
    flags:          flags          ?? this.flags,
    publishState:   publishState   ?? this.publishState,
    lastModified:   lastModified   ?? this.lastModified,
    lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
  );
}