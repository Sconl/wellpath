// lib/spaces/space_site/screen_home/screen_home_main.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// QP CANON: space_site › screen_home (screen_entry)
// ─────────────────────────────────────────────────────────────────────────────
//
// ADMIN WIRING
//   Watches effectiveSiteConfigProvider and effectiveFlagsProvider from
//   core/admin/admin_state.dart. When isAdminPreviewProvider is true, both
//   providers return draft values set by the admin control plane. When false,
//   they return the published const config (kWellPathSiteConfig) and default
//   flags — zero admin overhead in production.
//
// FILE RENAMED FROM: site_landing_page.dart → screen_home_main.dart
//   Class name kept as SiteLandingPage for router compatibility.
//
// FOLDER CHANGES
//   The widgets/ subfolder has been deleted. All section widgets now live in:
//     section_core/        ← section_core_hero.dart, section_core_trust.dart
//     section_context/     ← section_context_stats.dart, section_context_steps.dart,
//                             section_context_features.dart, section_context_testimonials.dart
//     section_connect/     ← section_connect_cta.dart, section_connect_footer.dart
//   Shared primitives are in space_site_shared.dart at the screen_home root.
//
// PARALLAX DARK RECTANGLE FIX
//   Canvas lives in OverflowBox(maxHeight: viewport + 250px) so upward
//   parallax translation never exposes the dark scaffold background.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/marketing_top_nav.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/style/app_motion.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/developer_feedback_chat.dart';
import '../../../core/admin/admin_state.dart';
import '../../../core/admin/admin_schema.dart';
import '../space_site_config.dart';

// ── QP Canon section imports ──────────────────────────────────────────────────
import 'section_core/section_core_hero.dart';
import 'section_core/section_core_trust.dart';
import 'section_context/section_context_stats.dart';
import 'section_context/section_context_steps.dart';
import 'section_context/section_context_features.dart';
import 'section_context/section_context_testimonials.dart';
import 'section_connect/section_connect_cta.dart';
import 'section_connect/section_connect_footer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

/// Extra canvas height beyond the viewport. Must be ≥ ParallaxConfig.background.maxOffset
/// so upward parallax translation never exposes the dark scaffold below.
const double _kCanvasParallaxPad = 250.0;

// ─────────────────────────────────────────────────────────────────────────────
// SiteLandingPage — renamed file, same class name for router compatibility
// ─────────────────────────────────────────────────────────────────────────────

class SiteLandingPage extends ConsumerStatefulWidget {
  const SiteLandingPage({super.key});

  @override
  ConsumerState<SiteLandingPage> createState() => _SiteLandingPageState();
}

class _SiteLandingPageState extends ConsumerState<SiteLandingPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _heroCtrl;
  late final Animation<double>   _heroFade;
  late final Animation<Offset>   _heroSlide;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));

    Timer(const Duration(milliseconds: 200),
        () { if (mounted) _heroCtrl.forward(); });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  Widget get _gap => SizedBox(height: AppSpacing.xxl + AppSpacing.lg);

  @override
  Widget build(BuildContext context) {
    // ── Admin wiring ────────────────────────────────────────────────────────
    // effectiveSiteConfigProvider returns draft config when preview is on,
    // published const otherwise. Zero cost in production.
    final cfg   = ref.watch(effectiveSiteConfigProvider);
    final flags = ref.watch(effectiveFlagsProvider);

    return Scaffold(
      body: Stack(children: [

        // ── PARALLAX BACKGROUND ────────────────────────────────────────────
        Positioned.fill(
          child: LayoutBuilder(builder: (context, viewport) {
            return OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: viewport.maxHeight + _kCanvasParallaxPad,
              maxWidth:  viewport.maxWidth,
              child: SizedBox(
                height: viewport.maxHeight + _kCanvasParallaxPad,
                child: ParallaxLayer(
                  scrollController: _scrollCtrl,
                  config: flags.enableParallax
                      ? ParallaxConfig.background
                      : const ParallaxConfig(enabled: false),
                  child: AppCanvas(
                    type:          BackgroundType.constellation,
                    particleStyle: ParticleStyle.drift,
                    gradientStyle: GradientStyle.pulse,
                    showDepthMesh: flags.enableDepthMesh,
                    meshIntensity: 0.85,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
          }),
        ),

        // ── SCROLLABLE CONTENT ─────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, viewport) {
            return SingleChildScrollView(
              controller: _scrollCtrl,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cfg.pageMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: cfg.pagePaddingH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        SizedBox(height: kMarketingNavBarHeight),

                        // ════════════════════════════════════════════════════
                        // SECTION CORE
                        // ════════════════════════════════════════════════════

                        // block: core_identity + core_value + core_action
                        _HeroBlock(
                          viewport:    viewport,
                          fade:        _heroFade,
                          slide:       _heroSlide,
                          config:      cfg.hero,
                          flags:       flags,
                          onPrimary:   () => context.push(cfg.signupRoute),
                          onSecondary: () => context.push(cfg.featuresRoute),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // block: core_trust (optional §5.2 — screen_entry only)
                        if (flags.showTrustedStrip)
                          FadeTransition(
                            opacity: _heroFade,
                            child: SectionCoreTrust(config: cfg.trusted),
                          ),

                        // ════════════════════════════════════════════════════
                        // SECTION CONTEXT
                        // ════════════════════════════════════════════════════

                        if (flags.showStats) ...[
                          _gap,
                          SectionContextStats(config: cfg.stats),
                        ],

                        if (flags.showSteps) ...[
                          _gap,
                          SectionContextSteps(config: cfg.steps),
                        ],

                        if (flags.showFeatureCards) ...[
                          _gap,
                          SectionContextFeatures(config: cfg.features),
                        ],

                        if (flags.showTestimonials) ...[
                          _gap,
                          SectionContextTestimonials(config: cfg.testimonials),
                        ],

                        // ════════════════════════════════════════════════════
                        // SECTION CONNECT
                        // ════════════════════════════════════════════════════

                        if (flags.showCtaBanner) ...[
                          _gap,
                          SectionConnectCta(
                            config: cfg.cta,
                            onTap:  () => context.push(cfg.signupRoute),
                          ),
                        ],

                        SizedBox(height: AppSpacing.xxl),
                        SectionConnectFooter(config: cfg.footer),

                        SizedBox(height: kFabSize + kFabMarginBottom + AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        // ── FLOATING NAV ───────────────────────────────────────────────────
        MarketingTopNav(
          navItems:         cfg.nav.navItems,
          ctaLabel:         cfg.nav.ctaLabel,
          onCta:            () => context.push(cfg.loginRoute),
          onProfileTap:     () => context.push(cfg.loginRoute),
          profileIcon:      cfg.nav.profileIcon,
          profileTooltip:   cfg.nav.profileTooltip,
          scrollController: _scrollCtrl,
        ),

        // ── FEEDBACK FAB ───────────────────────────────────────────────────
        if (flags.showFab)
          Positioned(
            right: kFabMarginRight, bottom: kFabMarginBottom,
            child: AppFab(
              icon:    Icons.chat_bubble_outline,
              label:   'Feedback',
              tooltip: 'Chat with our AI assistant — share bugs, ideas, or feedback',
              onPressed: () => showDialog(
                context:            context,
                barrierColor:       AppColors.scrim,
                barrierDismissible: true,
                builder: (_) => const DeveloperFeedbackChat(page: 'landing'),
              ),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeroBlock — sizes to fill one viewport minus nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBlock extends StatelessWidget {
  final BoxConstraints viewport;
  final Animation<double> fade;
  final Animation<Offset>  slide;
  final SiteHeroConfig config;
  final AdminFeatureFlags   flags;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _HeroBlock({
    required this.viewport, required this.fade, required this.slide,
    required this.config,   required this.flags,
    required this.onPrimary, required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final h = math.max(
      460.0,
      (viewport.maxHeight - kMarketingNavBarHeight - 120.0).clamp(460.0, 780.0),
    );
    return SizedBox(
      height: h,
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: SectionCoreHero(
              config:           config,
              flags:            flags,
              onPrimary:        onPrimary,
              onSecondary:      onSecondary,
            ),
          ),
        ),
      ),
    );
  }
}