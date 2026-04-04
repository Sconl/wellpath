// lib/core/theme/app_branding.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Full rewrite — elevated to the brand foundation layer. This file is now
//     the first dependency in the chain. app_theme.dart reads from it, not the
//     other way around. No app_ imports anywhere in this file.
//   • BrandColors replaces the _kBrandPrimary/Secondary/Tertiary constants that
//     previously lived in app_theme.dart's CONFIG BLOCK
//   • BrandCopy replaces AppBrand — adds fontFamily so the typeface is a brand
//     decision, not a theme decision
//   • BrandAssets replaces AppAssets — same paths, renamed for consistency
//   • BrandLogo replaces WellPathLogo — name is now template-portable;
//     a new project changes BrandCopy.wordBold/Light and the widget updates
//   • Logo colors defined here in CONFIG — avoids the circular dependency that
//     would result from BrandLogo trying to read AppColors from app_theme.dart
// ─────────────────────────────────────────────────────────────────────────────

// WHO OWNS THIS FILE:
//
//   The branding team. Before a single screen is built, this file should be
//   complete. Everything downstream — the full color palette, typography scale,
//   gradients, decorations, shadows — derives from what is defined here.
//
//   A developer starting a new project from this template needs to:
//     1. Set the three brand seeds in the CONFIG BLOCK (BrandColors)
//     2. Set the font family (BrandCopy.fontFamily)
//     3. Set the name, tagline, domain, copyright, and word split (BrandCopy)
//     4. Add asset paths to BrandAssets as files are created
//     5. Done — app_theme.dart and everything downstream regenerates
//
// DEPENDENCY NOTE — SVG ASSETS:
//
//   SVG rendering requires the flutter_svg package.
//   Add to pubspec.yaml: flutter_svg: ^2.0.0+
//   BrandAssets paths are just strings — flutter_svg is only needed at the
//   call site: SvgPicture.asset(BrandAssets.logoSvg, width: 120)
//
// PWA ICONS + FAVICON:
//
//   Use flutter_launcher_icons to generate all sizes from one source image.
//   Add to dev_dependencies: flutter_launcher_icons: ^0.13.0
//   Configure the flutter_launcher_icons section in pubspec.yaml, then run:
//     flutter pub run flutter_launcher_icons
//   This generates all required PNG sizes and patches web/manifest.json.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// Everything that makes this brand distinct from any other lives here.
// Change these constants — the entire design system regenerates downstream.
// ─────────────────────────────────────────────────────────────────────────────

// ── Brand color seeds ─────────────────────────────────────────────────────────
// These three constants are the ONLY color inputs to the entire design system.
// app_theme.dart's color engine derives the full palette — backgrounds, surfaces,
// gradients, shadows, semantic colors, contrast-safe on-colors — from these alone.
//
// Primary   → dominant brand color. Hero gradient, buttons, links, focus rings,
//             progress bars, active nav states. Should be vivid and distinct.
// Secondary → supporting accent. Constellation lines, secondary buttons, avatar
//             gradients, info-level chips. Complements primary.
// Tertiary  → warm accent. Live status badges, tertiary CTAs, notification
//             highlights. Provides contrast or warmth against the cooler pair.
//
// Color strategy reference: brand_color_directive.md in Appendix G of the master
// canvas — full HSL algorithm, 60-30-10 rule, anti-patterns, WCAG enforcement.
const Color _kBrandPrimary   = Color(0xFF00CC66); // WellPath green — vivid, health-forward
const Color _kBrandSecondary = Color(0xFF0099CC); // cool blue — trust, technology
const Color _kBrandTertiary  = Color(0xFFFF8A65); // warm coral — energy, warmth

// ── Brand identity ────────────────────────────────────────────────────────────
// The font family is a brand decision, not a theme decision. It lives here so
// a rebrand that includes a typeface change requires only this file.
// app_theme.dart reads BrandCopy.fontFamily — it has no hardcoded font name.
const String _kFontFamily = 'Poppins';

// The wordmark split is the brand's visual signature. The weight contrast —
// bold + light — communicates stability and movement simultaneously.
const String _kWordBold   = 'Well';
const String _kWordLight  = 'Path';

// Standard brand copy used in screens, meta tags, legal text, footers.
const String _kAppName   = 'WellPath';
const String _kTagline   = 'Your fitness journey, connected.';
const String _kDomain    = 'wellpath-fitness.web.app';
const String _kCopyright = '© 2026 WellPath';

// ── Logo colors ───────────────────────────────────────────────────────────────
// BrandLogo cannot import AppColors — that would be a circular dependency
// (app_branding → app_theme → app_branding). Logo default colors are defined
// here as constants instead.
//
// These intentionally mirror AppColors.textPrimary and .textSecondary for
// dark backgrounds. For light backgrounds, pass explicit colors at the call site:
//   BrandLogo(boldColor: AppColors.lightTextPrimary,
//             lightColor: AppColors.lightTextSecondary)
const Color _kLogoBoldDefaultColor  = Color(0xFFFFFFFF); // white — matches AppColors.textPrimary
const Color _kLogoLightDefaultColor = Color(0x8AFFFFFF); // white 54% — matches AppColors.textSecondary

// ── Logo sizing ───────────────────────────────────────────────────────────────
// Font sizes per LogoSize variant. Calibrated per usage context.
// Adjust here; never hardcode sizes at the call site.
//
//   sm → nav bars, app bars — horizontal space is tight
//   md → card headers, auth screens, section titles
//   lg → landing page hero, primary marketing moments
//   xl → splash screen only
const double _kLogoFontSm = 22.0;
const double _kLogoFontMd = 32.0;
const double _kLogoFontLg = 48.0;
const double _kLogoFontXl = 64.0;

// Letter spacing scales with size — large wordmarks need more breathing room
// between characters to feel balanced rather than cramped.
const double _kLogoLetterSpacingSm = 1.0;
const double _kLogoLetterSpacingMd = 1.5;
const double _kLogoLetterSpacingLg = 3.0;
const double _kLogoLetterSpacingXl = 4.0;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// BrandColors — the three seed colors, exported to app_theme.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// These are the ONLY inputs to app_theme.dart's color engine. The engine reads:
//   BrandColors.primary / .secondary / .tertiary
//
// Do not add derived colors here — derivation is app_theme.dart's job.
// This class is intentionally minimal: three seeds, nothing else.

abstract class BrandColors {
  /// The dominant brand color. Drives the primary button gradient, focus rings,
  /// active states, and the hero background gradient.
  static const Color primary   = _kBrandPrimary;

  /// The supporting accent. Secondary buttons, avatar gradients,
  /// constellation lines, info-level chips.
  static const Color secondary = _kBrandSecondary;

  /// The warm accent. Live status badges, tertiary CTAs, notification
  /// highlights. Provides contrast against the cooler primary/secondary pair.
  static const Color tertiary  = _kBrandTertiary;
}


// ─────────────────────────────────────────────────────────────────────────────
// BrandCopy — identity strings and font
// ─────────────────────────────────────────────────────────────────────────────
//
// All brand text and the font family live here. One change propagates everywhere:
// UI copy, browser metadata, legal strings, OG tags, about screens, footers.

abstract class BrandCopy {
  /// The Google Font family name for the brand typeface.
  /// app_theme.dart reads this for AppTypography and AppTheme.textTheme.
  /// BrandLogo reads this to render the wordmark in the correct font.
  static const String fontFamily = _kFontFamily;

  /// Bold half of the wordmark — always rendered at FontWeight.w700.
  static const String wordBold   = _kWordBold;

  /// Light half of the wordmark — always rendered at FontWeight.w300.
  static const String wordLight  = _kWordLight;

  /// Full app name as a plain string — used in page titles, snack bars,
  /// system notifications, and anywhere the wordmark split isn't appropriate.
  static const String appName    = _kAppName;

  /// Brand tagline — used in OG descriptions, onboarding subtitles,
  /// about screens, and app store listings.
  static const String tagline    = _kTagline;

  /// Canonical domain — used for link sharing, meta tags, deep link config.
  static const String domain     = _kDomain;

  /// Copyright line — used in footer, legal screen, app info sheet.
  static const String copyright  = _kCopyright;
}


// ─────────────────────────────────────────────────────────────────────────────
// BrandAssets — the complete asset path registry
// ─────────────────────────────────────────────────────────────────────────────
//
// Every asset path in the app lives here. No inline path strings anywhere else.
// When a file is renamed or moved, one update here propagates everywhere.
//
// Paths marked // PLACEHOLDER do not exist yet. To activate one:
//   1. Create the file at the path shown
//   2. Register it in pubspec.yaml under flutter: assets:
//   3. Remove the // PLACEHOLDER comment

abstract class BrandAssets {

  // ── Animated headers ────────────────────────────────────────────────────────
  // GIF / Lottie assets used in page hero areas. Versioned filenames prevent
  // cached old files from colliding with updates.
  static const String headerGifLanding =
      'animated-gifs/20260312_asset_animated_text_wellpath_landing_page_header_v1.0.0.gif';

  // ── Logo — SVG variants ──────────────────────────────────────────────────────
  // SVG is preferred over PNG for logos — it scales to any density, recolors
  // via ColorFilter for dark/light mode, and keeps the bundle smaller.
  //
  // logoSvg       → full wordmark with bold/light split (colored version)
  // logoMarkSvg   → icon-only mark without the text (for favicons, small spaces)
  // logoMonoDark  → white wordmark on transparent — use on dark backgrounds
  // logoMonoLight → dark wordmark on transparent — use on light backgrounds
  static const String logoSvg        = 'assets/brand/wellpath_logo.svg';            // PLACEHOLDER
  static const String logoMarkSvg    = 'assets/brand/wellpath_logomark.svg';        // PLACEHOLDER
  static const String logoMonoDark   = 'assets/brand/wellpath_logo_mono_dark.svg';  // PLACEHOLDER
  static const String logoMonoLight  = 'assets/brand/wellpath_logo_mono_light.svg'; // PLACEHOLDER

  // ── App icons / PWA ──────────────────────────────────────────────────────────
  // icon512 is the master — flutter_launcher_icons generates all other sizes.
  // See the flutter_launcher_icons note at the top of this file.
  static const String icon192 = 'assets/icons/wellpath_icon_192.png'; // PLACEHOLDER
  static const String icon512 = 'assets/icons/wellpath_icon_512.png'; // PLACEHOLDER — master source
  static const String favicon = 'assets/icons/wellpath_favicon_32.png'; // PLACEHOLDER

  // ── Social / OG ─────────────────────────────────────────────────────────────
  // Referenced in web/index.html og:image meta tag. Standard size is 1200×630px.
  // Also used as the App Store / Play Store cover image.
  static const String ogImage = 'assets/brand/wellpath_og_1200x630.png'; // PLACEHOLDER

  // ── Feature illustrations — SVG ──────────────────────────────────────────────
  // One illustration per feature area — shown in empty states and onboarding.
  // SVG so they recolor via ColorFilter to match the brand palette without
  // needing separate dark / light / accent variants.
  //
  // Tinting pattern:
  //   SvgPicture.asset(
  //     BrandAssets.illuBookingsEmpty,
  //     colorFilter: ColorFilter.mode(AppColors.primary.withValues(alpha: 0.5), BlendMode.srcIn),
  //   )
  static const String illuBookingsEmpty   = 'assets/illustrations/empty_bookings.svg';    // PLACEHOLDER
  static const String illuWellnessEmpty   = 'assets/illustrations/empty_wellness.svg';    // PLACEHOLDER
  static const String illuTrainersEmpty   = 'assets/illustrations/empty_trainers.svg';    // PLACEHOLDER
  static const String illuOnboardDiscover = 'assets/illustrations/onboard_discover.svg';  // PLACEHOLDER
  static const String illuOnboardLog      = 'assets/illustrations/onboard_log.svg';       // PLACEHOLDER
  static const String illuOnboardBook     = 'assets/illustrations/onboard_book.svg';      // PLACEHOLDER
}


// ─────────────────────────────────────────────────────────────────────────────
// LogoSize — controls BrandLogo scale
// ─────────────────────────────────────────────────────────────────────────────

/// Controls font size and letter-spacing of the BrandLogo wordmark.
/// Maps to the constants in the CONFIG BLOCK above.
///
/// - [sm] → nav bars, app bars
/// - [md] → card headers, auth screens, section titles
/// - [lg] → landing page hero, primary marketing moments
/// - [xl] → splash screen only
enum LogoSize { sm, md, lg, xl }


// ─────────────────────────────────────────────────────────────────────────────
// BrandLogo — the brand wordmark widget
// ─────────────────────────────────────────────────────────────────────────────
//
// The bold/light word split is the brand's visual signature. One word is
// always heavy, one is always light — the weight contrast communicates
// stability (bold) and movement (light) simultaneously.
//
// This is the single source of that pattern. Change BrandCopy.wordBold,
// BrandCopy.wordLight, BrandCopy.fontFamily, or the logo sizes in the CONFIG
// BLOCK and the widget updates everywhere with no other changes needed.
//
// WHY BRANDLOGO USES GOOGLEFONTS DIRECTLY (not AppTypography):
//   AppTypography lives in app_theme.dart, which imports this file.
//   If BrandLogo imported app_theme.dart, there would be a circular dependency:
//   app_branding → app_theme → app_branding. So BrandLogo calls
//   GoogleFonts.getFont() directly with BrandCopy.fontFamily — the exact
//   same internal call that AppTypography._f() makes. The logic is not
//   duplicated; only the GoogleFonts call site is, which is intentional.
//
// USAGE:
//   BrandLogo()                                  → md, white on dark (default)
//   BrandLogo(size: LogoSize.lg)                 → landing page hero (48pt)
//   BrandLogo(size: LogoSize.sm)                 → app bar / nav bar (22pt)
//   BrandLogo(size: LogoSize.xl)                 → splash screen (64pt)
//   BrandLogo(boldColor: AppColors.lightTextPrimary,
//             lightColor: AppColors.lightTextSecondary)  → light backgrounds
//   BrandLogo(boldColor: AppColors.primary)              → accent bold half

class BrandLogo extends StatelessWidget {
  final LogoSize size;

  /// Override the bold half color.
  /// Default: white — correct for dark backgrounds.
  /// Pass AppColors.lightTextPrimary for light backgrounds.
  final Color? boldColor;

  /// Override the light half color.
  /// Default: white 54% — correct for dark backgrounds.
  /// Pass AppColors.lightTextSecondary for light backgrounds.
  final Color? lightColor;

  /// Override letter-spacing for both halves. Leave null for the
  /// size-appropriate default from the CONFIG BLOCK.
  final double? letterSpacing;

  const BrandLogo({
    super.key,
    this.size         = LogoSize.md,
    this.boldColor,
    this.lightColor,
    this.letterSpacing,
  });

  double get _fontSize {
    switch (size) {
      case LogoSize.sm: return _kLogoFontSm;
      case LogoSize.md: return _kLogoFontMd;
      case LogoSize.lg: return _kLogoFontLg;
      case LogoSize.xl: return _kLogoFontXl;
    }
  }

  double get _spacing {
    if (letterSpacing != null) return letterSpacing!;
    switch (size) {
      case LogoSize.sm: return _kLogoLetterSpacingSm;
      case LogoSize.md: return _kLogoLetterSpacingMd;
      case LogoSize.lg: return _kLogoLetterSpacingLg;
      case LogoSize.xl: return _kLogoLetterSpacingXl;
    }
  }

  // Same call pattern as AppTypography._f() in app_theme.dart.
  // The duplication is of the call site, not the logic — intentional and
  // documented. See the WHY note above.
  TextStyle _style(FontWeight weight, Color color) => GoogleFonts.getFont(
    BrandCopy.fontFamily,
    fontWeight:    weight,
    fontSize:      _fontSize,
    letterSpacing: _spacing,
    color:         color,
    height:        1.0, // wordmarks don't need line height rhythm
  );

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text:  BrandCopy.wordBold,
            style: _style(FontWeight.w700, boldColor  ?? _kLogoBoldDefaultColor),
          ),
          TextSpan(
            text:  BrandCopy.wordLight,
            style: _style(FontWeight.w300, lightColor ?? _kLogoLightDefaultColor),
          ),
        ],
      ),
    );
  }
}