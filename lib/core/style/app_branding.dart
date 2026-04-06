// lib/core/style/app_branding.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial release — elevated to brand foundation layer. First in dependency
//     chain. app_theme.dart reads from here, not the other way around.
//   • BrandColors replaces _kBrandPrimary/Secondary/Tertiary from app_theme.dart
//   • BrandCopy replaces AppBrand — adds fontFamily (typeface is a brand decision)
//   • BrandAssets replaces AppAssets — same paths, renamed for consistency
//   • Logo colors defined here in CONFIG — avoids circular dependency with app_theme
//   • BrandLogo rewritten — asset-first (SVG primary, any image format supported)
//     with typographic wordmark as automatic fallback when assets are absent/fail
//   • LogoShape enum added — icon / horizontal / vertical (three layout variants)
//   • LogoVariant enum added — colored / white / black (three color treatments)
//   • White and black derived at render time via ColorFilter.mode — one colored
//     asset per shape is all that's needed; no extra files for mono variants
//   • Non-SVG formats (PNG, WebP, JPG) handled transparently via Image.asset
//     + ColorFiltered wrapper — client can hand off any format, widget adapts
//   • _BrandLogoTypographic extracted — the old RichText wordmark is now a
//     private fallback, not the primary render path; it still looks correct
//   • BrandAssets restructured — logoHorizontal / logoVertical / logoIcon (nullable)
//   • BrandAssets gains: favicon, appIconAndroid, appIconIos (nullable, optional)
//   • BrandLogoEngine added — static convenience builders for all 9 logo variants
//     (3 shapes × 3 color treatments); use these instead of constructing BrandLogo
//     with params manually every time throughout the app
//   • CONFIG BLOCK reordered — brand colors first, then logo paths, then fonts,
//     then identity copy. Matches the dependency/priority order of the system.
//   • Single fontFamily replaced with 5-role font system:
//     kFontHero / kFontDisplay / kFontText / kFontAccent / kFontSignature
//     All default to Poppins as placeholder — swap per role without touching
//     anything outside the CONFIG BLOCK
//   • BrandCopy.fontFamily removed — replaced with fontHero / fontDisplay /
//     fontText / fontAccent / fontSignature exposing the full font system
//   • File path updated: lib/core/theme/ → lib/core/style/
// ─────────────────────────────────────────────────────────────────────────────

// WHO OWNS THIS FILE:
//
//   The branding team. Complete this before any screen is built — everything
//   downstream derives from what's defined here.
//
//   Starting a new project from this template:
//     1. Set the three brand seeds (BrandColors)
//     2. Drop logo SVGs into assets/, update the three _kLogo* paths
//     3. Set each font role in the Typography section of the CONFIG BLOCK
//     4. Set name, tagline, domain, copyright, word split (BrandCopy)
//     5. Register all asset paths in pubspec.yaml under flutter: assets:
//     Done — everything in app_theme.dart and downstream regenerates.
//
// SVG PACKAGE:
//
//   BrandLogo uses flutter_svg for SVG rendering. pubspec.yaml must have:
//     flutter_svg: ^2.0.7+    ← errorBuilder requires ≥ 2.0.7
//
// APP ICONS / FAVICON:
//
//   appIconAndroid / appIconIos are source files for flutter_launcher_icons.
//   NOT loaded at runtime — the app runs fine without them.
//   dev_dependencies: flutter_launcher_icons: ^0.13.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ── Brand color seeds ─────────────────────────────────────────────────────────
// The only three color inputs to the entire design system.
// app_theme.dart's color engine derives every color token from these alone.
//
// Primary   → dominant. Hero gradient, buttons, links, active states.
// Secondary → supporting accent. Constellation lines, info chips.
// Tertiary  → warm accent. Live badges, tertiary CTAs, notification highlights.
const Color _kBrandPrimary = Color(0xFF00CC66); // WellPath green
const Color _kBrandSecondary = Color(0xFF0099CC); // cool blue
const Color _kBrandTertiary = Color(0xFFFF8A65); // warm coral

// ── Logo asset paths ──────────────────────────────────────────────────────────
// One colored asset per logo shape. null = not created yet.
// BrandLogo and BrandLogoEngine fall back to the typographic wordmark
// automatically when any path is null or the asset fails to load.
//
// FORMATS: SVG is preferred — ColorFilter handles white/black derivation at
// render time, so one colored file per shape is all you need. PNG, WebP, JPG
// also work — the widget detects the extension and routes accordingly.
//
// Register every non-null path in pubspec.yaml under flutter: assets:
const String? _kLogoHorizontal =
    'assets/logos/20260326_wellpath_logo_horizontal_primary_color.svg';
// PLACEHOLDER → 'assets/brand/logo_horizontal.svg'
const String? _kLogoVertical =
    'assets/logos/20260326_wellpath_logo_vertical_primary_color.svg'; // PLACEHOLDER → 'assets/brand/logo_vertical.svg'
const String? _kLogoIcon =
    'assets/logos/20260326_wellpath_logo_icon_primary_color.svg'; // PLACEHOLDER → 'assets/brand/logo_icon.svg'

// ── Web / PWA assets ──────────────────────────────────────────────────────────
// favicon goes in web/index.html — not loaded by Flutter widget code at runtime.
const String? _kFavicon = null; // PLACEHOLDER → 'assets/brand/favicon.png'

// ── App icons — build tooling only, not runtime assets ────────────────────────
// flutter_launcher_icons reads these at build time to generate all platform
// sizes. The app runs fine without them — only needed before store submission.
const String? _kAppIconAndroid =
    null; // PLACEHOLDER → 'assets/icons/app_icon.png'
const String? _kAppIconIos = null; // PLACEHOLDER → 'assets/icons/app_icon.png'

// ── Typography — 5 font roles ─────────────────────────────────────────────────
// Each role serves a distinct purpose. Swap fonts per role without touching
// any widget code — BrandCopy exposes these to AppTypography and everywhere else.
// All currently set to Poppins as the working placeholder.
//
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │ kFontHero      — Brand moments only. Splash, landing hero, "ACE" moments.  │
// │                  Expressive, stylish. Should appear in <5% of UI.          │
// │                  Future: ClashDisplay, Sora, Playfair Display               │
// │                                                                             │
// │ kFontDisplay   — App structure. Page titles, section headers, card headers. │
// │                  Readable at large sizes. Neutral but distinct from body.   │
// │                  Future: Barlow, Plus Jakarta Sans, DM Sans                 │
// │                                                                             │
// │ kFontText      — Everything the user lives in. Body, forms, buttons,        │
// │                  inputs, labels. Should be the most readable of the set.    │
// │                  Keep this stable — changing it reshapes the entire app.    │
// │                  Current: Poppins (working, no change needed)               │
// │                                                                             │
// │ kFontAccent    — Precision/data layer. Numbers, stats, timestamps, badges,  │
// │                  metadata. Can be monospace or tighter/sharper than Text.   │
// │                  Adds visual contrast without competing with body copy.     │
// │                  Future: Fira Code, JetBrains Mono, DM Mono                │
// │                                                                             │
// │ kFontSignature — Emotional layer only. NOT a system font.                  │
// │                  Greetings, achievements, milestone moments, empty states   │
// │                  with warmth ("Nothing here yet…"), onboarding completion.  │
// │                  Humanizes automation. Keep usage below 3% of UI text.     │
// │                  Future: Allura, Dancing Script, Roslindale                 │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// The typography table in AppTypography (app_theme.dart) documents which
// font role each text style uses. When you swap a font here, that swap
// applies automatically to every text style that references that role.
const String _kFontHero =
    'Poppins'; // PLACEHOLDER — swap to ClashDisplay, Sora, etc.
const String _kFontDisplay =
    'Poppins'; // PLACEHOLDER — swap to Barlow, DM Sans, etc.
const String _kFontText =
    'Poppins'; // Working — Poppins is correct for this role
const String _kFontAccent =
    'Poppins'; // PLACEHOLDER — swap to Fira Code, JetBrains Mono, etc.
const String _kFontSignature =
    'Poppins'; // PLACEHOLDER — swap to Allura, Dancing Script, etc.

// ── Brand identity copy ───────────────────────────────────────────────────────
// The wordmark split is the brand's visual signature — bold stability, light
// movement. One change here updates BrandLogoTypographic everywhere it renders.
const String _kWordBold = 'Well';
const String _kWordLight = 'Path';
const String _kAppName = 'WellPath';
const String _kTagline = 'Your fitness journey, connected.';
const String _kDomain = 'wellpath-fitness.web.app';
const String _kCopyright = '© 2026 WellPath';

// ── Logo fallback colors — typographic fallback only ─────────────────────────
// Only used by _BrandLogoTypographic when no asset renders.
// Hardcoded here to avoid circular dependency with app_theme.dart.
// These intentionally mirror AppColors.textPrimary/.textSecondary.
const Color _kLogoBoldDefaultColor = Color(0xFFFFFFFF); // white
const Color _kLogoLightDefaultColor = Color(0x8AFFFFFF); // white 54%

// ── Logo sizing — typographic fallback only ───────────────────────────────────
// Asset logo size is controlled by width/height passed to BrandLogo/BrandLogoEngine.
// These only matter when the typographic fallback renders.
const double _kLogoFontSm = 22.0;
const double _kLogoFontMd = 36.0;
const double _kLogoFontLg = 48.0;
const double _kLogoFontXl = 64.0;

const double _kLogoLetterSpacingSm = 1.0;
const double _kLogoLetterSpacingMd = 1.5;
const double _kLogoLetterSpacingLg = 3.0;
const double _kLogoLetterSpacingXl = 4.0;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// BrandColors
// ─────────────────────────────────────────────────────────────────────────────
//
// Three seeds. Nothing else. Don't add derived colors here.

abstract class BrandColors {
  /// Dominant brand color — buttons, hero gradient, focus rings, active states.
  static const Color primary = _kBrandPrimary;

  /// Supporting accent — secondary buttons, avatar gradients, constellation lines.
  static const Color secondary = _kBrandSecondary;

  /// Warm accent — live badges, tertiary CTAs, notification highlights.
  static const Color tertiary = _kBrandTertiary;
}

// ─────────────────────────────────────────────────────────────────────────────
// BrandCopy — identity strings and font roles
// ─────────────────────────────────────────────────────────────────────────────
//
// All brand text and all font role names live here.
// app_theme.dart's AppTypography reads the font getters — swap a font in the
// CONFIG BLOCK and it propagates to every text style that uses that role.

abstract class BrandCopy {
  // ── Font roles ─────────────────────────────────────────────────────────────
  // AppTypography (app_theme.dart) reads these for each text style.
  // BrandLogo reads fontText for the typographic fallback.
  // Use fontSignature directly at emotional call sites — it has no standard
  // AppTypography style because its use is intentionally rare and contextual.

  /// Brand identity + hero moments. <5% of UI. Splash, landing, big statements.
  static const String fontHero = _kFontHero;

  /// Page/section structure. Headings h1–h5, card titles, modal headers.
  static const String fontDisplay = _kFontDisplay;

  /// The system workhorse. Body, forms, buttons, inputs, labels — most of the UI.
  static const String fontText = _kFontText;

  /// Data precision layer. Numbers, stats, timestamps, chips, badges, overlines.
  static const String fontAccent = _kFontAccent;

  /// Emotional signature. Greetings, milestones, encouragement, empty states.
  /// Use sparingly — overuse destroys the effect. Target <3% of visible text.
  static const String fontSignature = _kFontSignature;

  // ── Brand identity ─────────────────────────────────────────────────────────

  /// Bold half of the typographic wordmark — always at FontWeight.w700.
  static const String wordBold = _kWordBold;

  /// Light half of the typographic wordmark — always at FontWeight.w300.
  static const String wordLight = _kWordLight;

  /// Full app name — page titles, notifications, anywhere the split isn't right.
  static const String appName = _kAppName;

  /// Brand tagline — OG descriptions, onboarding subtitles, about screens.
  static const String tagline = _kTagline;

  /// Canonical domain — link sharing, meta tags, deep link config.
  static const String domain = _kDomain;

  /// Copyright line — footer, legal screen, app info sheet.
  static const String copyright = _kCopyright;
}

// ─────────────────────────────────────────────────────────────────────────────
// BrandAssets — complete asset path registry
// ─────────────────────────────────────────────────────────────────────────────
//
// Every asset path in the app lives here. No inline path strings anywhere else.
// Nullable paths are not created yet — the app runs without them.

abstract class BrandAssets {
  // ── Animated headers ────────────────────────────────────────────────────────
  static const String headerGifLanding =
      'animated-gifs/20260312_asset_animated_text_wellpath_landing_page_header_v1.0.0.gif';

  // ── Logo — one colored asset per shape ───────────────────────────────────
  // White and black variants are DERIVED at render time via ColorFilter —
  // you do NOT need separate white or black asset files.
  // BrandLogoEngine exposes all 9 combinations (3 shapes × 3 variants) as
  // named widget builders. Set these paths once the SVGs are ready.
  static const String? logoHorizontal = _kLogoHorizontal; // PLACEHOLDER
  static const String? logoVertical = _kLogoVertical; // PLACEHOLDER
  static const String? logoIcon = _kLogoIcon; // PLACEHOLDER

  // ── Web / PWA ────────────────────────────────────────────────────────────
  static const String? favicon = _kFavicon; // PLACEHOLDER

  // ── App icons — build tooling only ───────────────────────────────────────
  static const String? appIconAndroid = _kAppIconAndroid; // PLACEHOLDER
  static const String? appIconIos = _kAppIconIos; // PLACEHOLDER

  // ── Social / OG ──────────────────────────────────────────────────────────
  static const String ogImage =
      'assets/brand/wellpath_og_1200x630.png'; // PLACEHOLDER

  // ── Feature illustrations ─────────────────────────────────────────────────
  static const String illuBookingsEmpty =
      'assets/illustrations/empty_bookings.svg'; // PLACEHOLDER
  static const String illuWellnessEmpty =
      'assets/illustrations/empty_wellness.svg'; // PLACEHOLDER
  static const String illuTrainersEmpty =
      'assets/illustrations/empty_trainers.svg'; // PLACEHOLDER
  static const String illuOnboardDiscover =
      'assets/illustrations/onboard_discover.svg'; // PLACEHOLDER
  static const String illuOnboardLog =
      'assets/illustrations/onboard_log.svg'; // PLACEHOLDER
  static const String illuOnboardBook =
      'assets/illustrations/onboard_book.svg'; // PLACEHOLDER
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// Which logo layout to render.
///
/// [icon]       — mark only, no text. App bars, tight spaces, favicon-scale.
/// [horizontal] — mark beside wordmark, side-by-side. Most common.
/// [vertical]   — mark stacked above wordmark. Splash, auth, card headers.
enum LogoShape { icon, horizontal, vertical }

/// Color treatment applied at render time.
///
/// [colored] — render the asset as-is. No filter.
/// [white]   — force all opaque pixels white via ColorFilter. Dark/colored bgs.
/// [black]   — force all opaque pixels black via ColorFilter. Light bgs.
///
/// White/black are derived from the colored asset — no separate asset files needed.
enum LogoVariant { colored, white, black }

/// Font size for the typographic fallback only.
/// Irrelevant when a real asset renders — use BrandLogo.width / .height instead.
enum LogoSize { sm, md, lg, xl }

// ─────────────────────────────────────────────────────────────────────────────
// BrandLogoEngine — all 9 logo variants as named widget builders
// ─────────────────────────────────────────────────────────────────────────────
//
// The engine exposes all combinations of shape × color treatment as named static
// methods. Use these throughout the app instead of constructing BrandLogo with
// params manually — it makes intent clear at the call site and ensures consistency.
//
// HOW THE MONO DERIVATION WORKS:
//   Only one colored SVG per shape is needed. When you request a white or black
//   variant, ColorFilter.mode() replaces every painted pixel with the target color
//   while preserving the original alpha channel. Transparent areas stay transparent.
//   This is the same technique design tools use for "recolor" operations.
//
//   ColorFilter.mode(Colors.white, BlendMode.srcIn)
//     → every filled pixel → white, transparency → transparent
//   ColorFilter.mode(Colors.black, BlendMode.srcIn)
//     → every filled pixel → black, transparency → transparent
//
// USAGE:
//   BrandLogoEngine.horizontalColored(height: 32)    → app bar, nav
//   BrandLogoEngine.horizontalWhite(height: 28)      → over hero gradient
//   BrandLogoEngine.horizontalBlack(height: 28)      → over white bg
//   BrandLogoEngine.verticalColored(height: 80)      → splash, auth
//   BrandLogoEngine.verticalWhite(height: 64)        → dark splash
//   BrandLogoEngine.iconColored(width: 40)           → small tight spaces
//   BrandLogoEngine.iconWhite(width: 32)             → nav bar icon
//   BrandLogoEngine.iconBlack(width: 32)             → light header
//
// All methods fall back to the typographic wordmark automatically if the
// underlying asset path is null or the file fails to load.

abstract class BrandLogoEngine {
  // ── Horizontal (wordmark) ─────────────────────────────────────────────────

  /// Full color horizontal logo. Use on dark/neutral backgrounds.
  static Widget horizontalColored(
          {double? width,
          double? height = 32,
          LogoSize fallbackSize = LogoSize.md}) =>
      BrandLogo(
          shape: LogoShape.horizontal,
          variant: LogoVariant.colored,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  /// White horizontal logo. Use over gradients, dark backgrounds, hero images.
  static Widget horizontalWhite(
          {double? width,
          double? height = 28,
          LogoSize fallbackSize = LogoSize.md}) =>
      BrandLogo(
          shape: LogoShape.horizontal,
          variant: LogoVariant.white,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  /// Black horizontal logo. Use on white/very light backgrounds.
  static Widget horizontalBlack(
          {double? width,
          double? height = 28,
          LogoSize fallbackSize = LogoSize.md}) =>
      BrandLogo(
          shape: LogoShape.horizontal,
          variant: LogoVariant.black,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  // ── Vertical (stacked) ────────────────────────────────────────────────────

  /// Full color vertical logo. Splash screens, auth pages, onboarding.
  static Widget verticalColored(
          {double? width,
          double? height = 80,
          LogoSize fallbackSize = LogoSize.lg}) =>
      BrandLogo(
          shape: LogoShape.vertical,
          variant: LogoVariant.colored,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  /// White vertical logo. Dark splash/auth screens.
  static Widget verticalWhite(
          {double? width,
          double? height = 64,
          LogoSize fallbackSize = LogoSize.lg}) =>
      BrandLogo(
          shape: LogoShape.vertical,
          variant: LogoVariant.white,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  /// Black vertical logo. Light auth/marketing screens.
  static Widget verticalBlack(
          {double? width,
          double? height = 64,
          LogoSize fallbackSize = LogoSize.lg}) =>
      BrandLogo(
          shape: LogoShape.vertical,
          variant: LogoVariant.black,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  // ── Icon (mark only) ─────────────────────────────────────────────────────

  /// Full color icon mark. Favicons, tight app-bar spaces, avatar-scale uses.
  static Widget iconColored(
          {double? width = 40,
          double? height,
          LogoSize fallbackSize = LogoSize.sm}) =>
      BrandLogo(
          shape: LogoShape.icon,
          variant: LogoVariant.colored,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  /// White icon mark. Dark nav bars, overlay headers.
  static Widget iconWhite(
          {double? width = 32,
          double? height,
          LogoSize fallbackSize = LogoSize.sm}) =>
      BrandLogo(
          shape: LogoShape.icon,
          variant: LogoVariant.white,
          width: width,
          height: height,
          fallbackSize: fallbackSize);

  /// Black icon mark. Light backgrounds, printed materials.
  static Widget iconBlack(
          {double? width = 32,
          double? height,
          LogoSize fallbackSize = LogoSize.sm}) =>
      BrandLogo(
          shape: LogoShape.icon,
          variant: LogoVariant.black,
          width: width,
          height: height,
          fallbackSize: fallbackSize);
}

// ─────────────────────────────────────────────────────────────────────────────
// BrandLogo — asset-first logo widget
// ─────────────────────────────────────────────────────────────────────────────
//
// In most cases prefer BrandLogoEngine.*() over constructing this directly —
// the named builders are clearer at the call site. Construct BrandLogo directly
// only when you need full param control (e.g., custom fallback colors).
//
// PRIMARY PATH — asset rendering:
//   SVG → flutter_svg with ColorFilter for white/black variants.
//   Non-SVG → Image.asset with ColorFiltered wrapper.
//
// FALLBACK PATH — typographic wordmark:
//   Kicks in when (a) path is null, or (b) the asset fails to load.

class BrandLogo extends StatelessWidget {
  final LogoShape shape;
  final LogoVariant variant;
  final double? width;
  final double? height;
  final LogoSize fallbackSize;
  final Color? boldColor;
  final Color? lightColor;

  const BrandLogo({
    super.key,
    this.shape = LogoShape.horizontal,
    this.variant = LogoVariant.colored,
    this.width,
    this.height,
    this.fallbackSize = LogoSize.md,
    this.boldColor,
    this.lightColor,
  });

  String? get _assetPath {
    switch (shape) {
      case LogoShape.horizontal:
        return BrandAssets.logoHorizontal;
      case LogoShape.vertical:
        return BrandAssets.logoVertical;
      case LogoShape.icon:
        return BrandAssets.logoIcon;
    }
  }

  // null = no filter = render colored as-is.
  // BlendMode.srcIn replaces every painted pixel with the tint color while
  // preserving the original alpha — transparent areas stay transparent.
  ColorFilter? get _colorFilter {
    switch (variant) {
      case LogoVariant.colored:
        return null;
      case LogoVariant.white:
        return const ColorFilter.mode(Colors.white, BlendMode.srcIn);
      case LogoVariant.black:
        return const ColorFilter.mode(Colors.black, BlendMode.srcIn);
    }
  }

  Widget _fallback() => _BrandLogoTypographic(
        size: fallbackSize,
        boldColor: boldColor,
        lightColor: lightColor,
      );

  // Default height based on fallbackSize if height not specified
  double? get _defaultHeight {
    if (height != null) return height;
    switch (fallbackSize) {
      case LogoSize.sm:
        return 22.0;
      case LogoSize.md:
        return 32.0;
      case LogoSize.lg:
        return 48.0;
      case LogoSize.xl:
        return 64.0;
    }
  }

  // Default width for icons
  double? get _defaultWidth {
    if (width != null) return width;
    if (shape == LogoShape.icon) {
      switch (fallbackSize) {
        case LogoSize.sm:
          return 22.0;
        case LogoSize.md:
          return 32.0;
        case LogoSize.lg:
          return 48.0;
        case LogoSize.xl:
          return 64.0;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetPath;
    if (path == null) return _fallback();

    final cf = _colorFilter;

    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: _defaultWidth,
        height: _defaultHeight,
        colorFilter: cf,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    // Non-SVG (PNG, WebP, JPG, animated GIF).
    Widget img = Image.asset(
      path,
      width: _defaultWidth,
      height: _defaultHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(),
    );

    // Skip the extra widget tree layer when no tinting is needed.
    if (cf != null) {
      img = ColorFiltered(colorFilter: cf, child: img);
    }

    return img;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BrandLogoTypographic — two-weight RichText wordmark (private fallback)
// ─────────────────────────────────────────────────────────────────────────────
//
// Uses BrandCopy.fontText directly via GoogleFonts — cannot import AppTypography
// because that would be circular (app_branding → app_theme → app_branding).
// The call pattern is identical to AppTypography._f(); only the call site differs.

class _BrandLogoTypographic extends StatelessWidget {
  final LogoSize size;
  final Color? boldColor;
  final Color? lightColor;
  // ignore: unused_field
  final double? letterSpacing;

  const _BrandLogoTypographic({
    this.size = LogoSize.md,
    this.boldColor,
    this.lightColor,
    // ignore: unused_element_parameter
    this.letterSpacing,
  });

  double get _fontSize {
    switch (size) {
      case LogoSize.sm:
        return _kLogoFontSm;
      case LogoSize.md:
        return _kLogoFontMd;
      case LogoSize.lg:
        return _kLogoFontLg;
      case LogoSize.xl:
        return _kLogoFontXl;
    }
  }

  double get _spacing {
    if (letterSpacing != null) return letterSpacing!;
    switch (size) {
      case LogoSize.sm:
        return _kLogoLetterSpacingSm;
      case LogoSize.md:
        return _kLogoLetterSpacingMd;
      case LogoSize.lg:
        return _kLogoLetterSpacingLg;
      case LogoSize.xl:
        return _kLogoLetterSpacingXl;
    }
  }

  TextStyle _style(FontWeight weight, Color color) => GoogleFonts.getFont(
        BrandCopy
            .fontText, // typographic fallback uses the system workhorse font
        fontWeight: weight,
        fontSize: _fontSize,
        letterSpacing: _spacing,
        color: color,
        height: 1.0,
      );

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: BrandCopy.wordBold,
            style: _style(FontWeight.w700, boldColor ?? _kLogoBoldDefaultColor),
          ),
          TextSpan(
            text: BrandCopy.wordLight,
            style:
                _style(FontWeight.w300, lightColor ?? _kLogoLightDefaultColor),
          ),
        ],
      ),
    );
  }
}
