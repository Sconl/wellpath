// lib/features/site/home/site_landing_page.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Site — SiteLandingPage
// ─────────────────────────────────────────────────────────────────────────────
// Composes all Site section widgets into a complete marketing landing page.
//
// LAYOUT
//   Stack
//   ├── AppCanvas (animated background)
//   │   └── SingleChildScrollView
//   │       ├── [nav clearance SizedBox]
//   │       ├── SiteHero            ← above fold
//   │       ├── SiteTrustedStrip    ← above fold (visible without scrolling)
//   │       ├── ── fold ──
//   │       ├── SiteStatsStrip
//   │       ├── SiteHowItWorks
//   │       ├── SiteFeatureHighlights
//   │       ├── SiteTestimonials
//   │       ├── SiteCtaBanner
//   │       └── SiteFooter
//   ├── SiteFloatingNav  (Positioned top: 0, never scrolls)
//   └── AppFab           (Positioned bottom-right, never scrolls)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/developer_feedback_chat.dart';
import '../site_config.dart';
import 'widgets/site_floating_nav.dart';
import 'widgets/site_hero.dart';
import 'widgets/site_trusted_strip.dart';
import 'widgets/site_stats.dart';
import 'widgets/site_how_it_works.dart';
import 'widgets/site_features.dart';
import 'widgets/site_testimonials.dart';
import 'widgets/site_cta_footer.dart';

class SiteLandingPage extends StatefulWidget {
  final SiteConfig config;
  const SiteLandingPage({super.key, required this.config});

  @override
  State<SiteLandingPage> createState() => _SiteLandingPageState();
}

class _SiteLandingPageState extends State<SiteLandingPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset>  _heroSlide;
  final ScrollController _scrollCtrl = ScrollController();

  SiteConfig get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));

    Timer(const Duration(milliseconds: 200), () {
      if (mounted) _heroCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // ── Background ─────────────────────────────────────────────────────
        AppCanvas(
          type:          BackgroundType.constellation,
          particleStyle: ParticleStyle.drift,
          gradientStyle: GradientStyle.pulse,
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(builder: (context, viewport) {
              return SingleChildScrollView(
                controller: _scrollCtrl,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _cfg.pageMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _cfg.pagePaddingH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Nav bar clearance
                          SizedBox(height: kSiteNavBarHeight),

                          // ── Hero (above fold) ─────────────────────────────
                          _HeroBlock(
                            viewport: viewport,
                            fade:  _heroFade,
                            slide: _heroSlide,
                            config:      _cfg.hero,
                            onPrimary:   () => context.push(_cfg.signupRoute),
                            onSecondary: () => context.push(_cfg.featuresRoute),
                          ),

                          SizedBox(height: AppSpacing.lg),

                          // ── Trusted strip (above fold) ────────────────────
                          FadeTransition(
                            opacity: _heroFade,
                            child: SiteTrustedStrip(config: _cfg.trusted),
                          ),

                          // ── Below-fold content ────────────────────────────
                          SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                          SiteStatsStrip(config: _cfg.stats),

                          SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                          SiteHowItWorks(config: _cfg.howItWorks),

                          SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                          SiteFeatureHighlights(config: _cfg.features),

                          SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                          SiteTestimonials(config: _cfg.testimonials),

                          SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                          SiteCtaBanner(
                            config: _cfg.cta,
                            onTap:  () => context.push(_cfg.signupRoute),
                          ),

                          SizedBox(height: AppSpacing.xxl),
                          SiteFooter(config: _cfg.footer),

                          // FAB clearance
                          SizedBox(height: kFabSize + kFabMarginBottom + AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Floating nav ───────────────────────────────────────────────────
        SiteFloatingNav(
          config:           _cfg,
          scrollController: _scrollCtrl,
          onCta:            () => context.push(_cfg.loginRoute),
          onProfileTap:     () => context.push(_cfg.loginRoute),
        ),

        // ── Feedback FAB ───────────────────────────────────────────────────
        Positioned(
          right: kFabMarginRight, bottom: kFabMarginBottom,
          child: AppFab(
            icon:    Icons.chat_bubble_outline,
            label:   'Feedback',
            tooltip: 'Chat with our AI assistant — share bugs, ideas, or feedback',
            onPressed: () => showDialog(
              context: context,
              barrierColor: AppColors.scrim,
              barrierDismissible: true,
              builder: (_) => const DeveloperFeedbackChat(page: 'landing'),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── _HeroBlock — sizes the hero to fill exactly one viewport height ─────────

class _HeroBlock extends StatelessWidget {
  final BoxConstraints viewport;
  final Animation<double> fade;
  final Animation<Offset>  slide;
  final SiteHeroConfig config;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _HeroBlock({
    required this.viewport,
    required this.fade,
    required this.slide,
    required this.config,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = math.max(
      460.0,
      (viewport.maxHeight - kSiteNavBarHeight - 120.0).clamp(460.0, 780.0),
    );
    return SizedBox(
      height: heroHeight,
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: SiteHero(
              config:      config,
              onPrimary:   onPrimary,
              onSecondary: onSecondary,
            ),
          ),
        ),
      ),
    );
  }
}