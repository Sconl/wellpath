// lib/spaces/space_site/features_page/features_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/marketing_top_nav.dart';
import '../../../core/navigation/nav_items.dart';
import '../../../core/style/app_branding.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_motion.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/developer_feedback_chat.dart';
import '../space_site_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double kFeaturesMaxWidth = 1100.0;
const double kFeaturesPaddingH = 60.0;

const bool _kShowHeroAnimation = true;

const String kFeaturesStatic =
    'Built for every part\nof your fitness life.';

const _TC kFeaturesTyping = TypingTextConfig(
  phrases: [
    'Built for every part\nof your fitness life.',
    'Discover.\nBook.\nTrack.',
    'Four pillars.\nOne platform.',
  ],
  fontSize: 44,
  headlineBlockHeight: 110,
);
typedef _TC = TypingTextConfig;

const String kFeaturesSubline =
    'Four integrated pillars — discovery, booking, wellness tracking, and smart '
    'reminders — work together so you never have to juggle multiple apps again.';

const List<_FeatureDeep> kFeatureDeeps = [
  _FeatureDeep(
    icon: Icons.person_search_rounded, eyebrow: 'Trainer Discovery', accentColor: 0,
    title: 'Find the right trainer,\nnot just any trainer.',
    body: 'Browse a curated roster of certified Mombasa trainers, each with a '
          'detailed profile covering specialties, pricing, availability windows, '
          'and verified client reviews. Filter by discipline — strength, yoga, HIIT, '
          'swimming, boxing, rehabilitation — and surface exactly who fits your '
          'schedule and goals.\n\n'
          'Every trainer profile includes certification details, session formats '
          '(in-gym, outdoor, virtual), and a live availability calendar.',
    bullets: [
      'Specialty filters: 10+ disciplines',
      'Verified certifications on every profile',
      'Location-aware results via Mapbox',
      'Real-time availability displayed upfront',
    ],
  ),
  _FeatureDeep(
    icon: Icons.event_available_rounded, eyebrow: 'Booking System', accentColor: 1,
    title: 'From browsing to booked\nin under thirty seconds.',
    body: 'WellPath\'s booking engine is built on an atomic Firestore transaction — '
          'meaning two people can never book the same slot simultaneously. Tap an '
          'available slot, confirm your booking, and receive a push notification '
          'within seconds on both sides.\n\n'
          'Trainers manage their bookings from a dedicated dashboard: confirm, '
          'reschedule, or cancel with a single tap.',
    bullets: [
      'Atomic booking — no double-booking, ever',
      'Instant push confirmation for user and trainer',
      'Trainer dashboard: confirm, cancel, reschedule',
      '24-hour session reminder for both parties',
    ],
  ),
  _FeatureDeep(
    icon: Icons.insights_rounded, eyebrow: 'Wellness Tracking', accentColor: 0,
    title: 'Three logs. One dashboard.\nThe full picture.',
    body: 'Log workouts, daily water intake, and sleep from the same screen. '
          'The weekly dashboard plots your data across a seven-day calendar, '
          'highlights streaks, and compares actuals against your personal goals.\n\n'
          'Goal setting is simple: choose a target for workouts per week, '
          'daily hydration, and sleep hours. Offline logging is fully supported.',
    bullets: [
      'Three log types: workout, water, sleep',
      'Weekly dashboard with 7-day calendar view',
      'Animated goal progress rings',
      'Offline-first — syncs when back online',
    ],
  ),
  _FeatureDeep(
    icon: Icons.notifications_active_rounded, eyebrow: 'Smart Reminders', accentColor: 1,
    title: 'The right nudge at\nthe right moment.',
    body: 'WellPath\'s notification layer is built on Firebase Cloud Messaging '
          'and runs across browser, Android, and iOS. Booking confirmations '
          'fire instantly. Session reminders go out 24 hours before your next '
          'appointment. A daily wellness prompt checks in at a time you choose.\n\n'
          'Every notification category is individually toggleable from the '
          'Notification Settings screen.',
    bullets: [
      'Instant booking push for user and trainer',
      '24-hour pre-session reminders',
      'Daily wellness check-in at your chosen time',
      'Granular per-category notification controls',
    ],
  ),
];

const List<_UpcomingItem> kUpcoming = [
  _UpcomingItem('Group class booking'),
  _UpcomingItem('Nutrition logging'),
  _UpcomingItem('Progress photo timeline'),
  _UpcomingItem('Trainer video consultations'),
  _UpcomingItem('Gym & facility finder'),
  _UpcomingItem('In-app messaging'),
];

class _FeatureDeep {
  final IconData icon; final String eyebrow; final String title;
  final String body; final List<String> bullets; final int accentColor;
  const _FeatureDeep({required this.icon, required this.eyebrow,
    required this.title, required this.body, required this.bullets,
    required this.accentColor});
}
class _UpcomingItem {
  final String label;
  const _UpcomingItem(this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// FeaturesScreen
// ─────────────────────────────────────────────────────────────────────────────

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        AppCanvas(
          type: BackgroundType.meshParticle, particleStyle: ParticleStyle.drift,
          gradientStyle: GradientStyle.pulse,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kFeaturesMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: kFeaturesPaddingH),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      SizedBox(height: kMarketingNavBarHeight),
                      SizedBox(height: AppSpacing.xxl),

                      SitePageHero(
                        eyebrow:        'Platform Features',
                        staticHeadline: kFeaturesStatic,
                        subline:        kFeaturesSubline,
                        typingConfig:   kFeaturesTyping,
                        showAnimation:  _kShowHeroAnimation,
                      ),

                      SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                      ...kFeatureDeeps.asMap().entries.map((e) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xxl + AppSpacing.lg),
                        child: _FeatureDeepSection(feature: e.value, flip: e.key.isOdd),
                      )),

                      _UpcomingSection(),
                      SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                      _FeaturesCta(onTap: () => context.push('/signup')),
                      SizedBox(height: AppSpacing.xxl),
                      _FeaturesFooter(),
                      SizedBox(height: kFabSize + kFabMarginBottom + AppSpacing.lg),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),

        MarketingTopNav(
          navItems: kDefaultMarketingNavItems, ctaLabel: 'Get Started →',
          scrollController: _scrollCtrl,
          onCta: () => context.push('/signup'),
          onProfileTap: () => context.push('/login'),
        ),

        Positioned(
          right: kFabMarginRight, bottom: kFabMarginBottom,
          child: AppFab(
            icon: Icons.chat_bubble_outline, label: 'Feedback',
            tooltip: 'Chat with our AI assistant — share feedback or ideas',
            onPressed: () => showDialog(context: context, barrierColor: AppColors.scrim,
              barrierDismissible: true,
              builder: (_) => const DeveloperFeedbackChat(page: 'features')),
          ),
        ),
      ]),
    );
  }
}

class _FeatureDeepSection extends StatelessWidget {
  final _FeatureDeep feature; final bool flip;
  const _FeatureDeepSection({required this.feature, required this.flip});

  Color get _accent => feature.accentColor == 0 ? AppColors.primary : AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 720;
      final copy   = _CopyColumn(feature: feature, accent: _accent);
      final visual = _VisualColumn(feature: feature, accent: _accent);
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: flip
            ? [Expanded(child: copy), SizedBox(width: AppSpacing.xxl), Expanded(child: visual)]
            : [Expanded(child: visual), SizedBox(width: AppSpacing.xxl), Expanded(child: copy)]);
      }
      return Column(children: [visual, SizedBox(height: AppSpacing.xl), copy]);
    });
  }
}

class _CopyColumn extends StatelessWidget {
  final _FeatureDeep feature; final Color accent;
  const _CopyColumn({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: accent.withAlpha(20), borderRadius: AppRadius.pillBR,
          border: Border.all(color: accent.withAlpha(50))),
        child: Text(feature.eyebrow.toUpperCase(),
            style: AppTypography.chip.copyWith(color: accent, fontSize: 10)),
      ),
      SizedBox(height: AppSpacing.md),
      Text(feature.title, style: AppTypography.h2.copyWith(fontSize: 28, height: 1.2)),
      SizedBox(height: AppSpacing.md),
      Text(feature.body, style: AppTypography.body.copyWith(height: 1.8, color: AppColors.textSecondary)),
      SizedBox(height: AppSpacing.lg),
      ...feature.bullets.map((b) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(margin: EdgeInsets.only(top: 6),
              width: 6, height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(b, style: AppTypography.bodySmall.copyWith(height: 1.5))),
        ]),
      )),
    ]);
  }
}

class _VisualColumn extends StatelessWidget {
  final _FeatureDeep feature; final Color accent;
  const _VisualColumn({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: AppRadius.cardBR,
        border: Border.all(color: accent.withAlpha(60), width: 1.5),
        boxShadow: [BoxShadow(color: accent.withAlpha(25), blurRadius: 40, spreadRadius: 2)],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Container(decoration: BoxDecoration(
          borderRadius: AppRadius.cardBR,
          gradient: RadialGradient(center: Alignment.center, radius: 1.0,
              colors: [accent.withAlpha(15), Colors.transparent]))),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
                color: accent.withAlpha(20), borderRadius: AppRadius.cardBR),
            child: Icon(feature.icon, size: 48, color: accent)),
          SizedBox(height: AppSpacing.lg),
          Text(feature.eyebrow, style: AppTypography.h5.copyWith(color: accent, fontSize: 15)),
        ])),
      ]),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: AppRadius.cardBR,
        border: Border.all(color: AppColors.border)),
      child: Column(children: [
        SiteSectionHeader(eyebrow: 'Coming Soon', headline: 'What\'s next on the roadmap'),
        SizedBox(height: AppSpacing.lg),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, alignment: WrapAlignment.center,
          children: kUpcoming.map((item) => Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.tint10(AppColors.secondary), borderRadius: AppRadius.pillBR,
              border: Border.all(color: AppColors.tint20(AppColors.secondary))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule_rounded, size: 13, color: AppColors.secondary),
              SizedBox(width: AppSpacing.xs),
              Text(item.label, style: AppTypography.chip.copyWith(
                  color: AppColors.secondary, fontSize: 12)),
            ]),
          )).toList()),
      ]),
    );
  }
}

class _FeaturesCta extends StatefulWidget {
  final VoidCallback onTap;
  const _FeaturesCta({required this.onTap});

  @override
  State<_FeaturesCta> createState() => _FeaturesCtaState();
}

class _FeaturesCtaState extends State<_FeaturesCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast, width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: _hovered ? AppGradients.buttonHover : AppGradients.button,
            borderRadius: AppRadius.cardBR,
            boxShadow: _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow),
          child: Column(children: [
            Text('Experience every feature yourself.',
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(fontSize: 24)),
            SizedBox(height: AppSpacing.sm),
            Text('Create a free account and explore WellPath today.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            SizedBox(height: AppSpacing.lg),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(60), borderRadius: AppRadius.pillBR,
                border: Border.all(color: AppColors.borderStrong)),
              child: Text('Create Free Account', style: AppTypography.button.copyWith(fontSize: 15)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FeaturesFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(height: 1, color: AppColors.border),
      SizedBox(height: AppSpacing.lg),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(BrandCopy.copyright, style: AppTypography.caption.copyWith(fontSize: 11)),
        GestureDetector(
          onTap: () => context.go('/landing'),
          child: Text('← Back to home',
              style: AppTypography.caption.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w500)),
        ),
      ]),
      SizedBox(height: AppSpacing.lg),
    ]);
  }
}