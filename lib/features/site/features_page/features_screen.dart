// lib/features/features_page/presentation/features_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// WellPath — Features marketing page.
// Public marketing screen. No auth required.
// Deep-dives into the four platform pillars with alternating layout.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_branding.dart';
import '../../../core/style/app_theme.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_nav_bar.dart';
import '../../../core/widgets/developer_feedback_chat.dart';
import '../../../core/constants/marketing_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double kFeaturesMaxWidth = 1100.0;
const double kFeaturesPaddingH = 60.0;
const double kFeaturesPaddingV = 32.0;

// ── Page hero ─────────────────────────────────────────────────────────────────
const String kFeaturesHeadline = 'Built for every part\nof your fitness life.';
const String kFeaturesSubline  =
    'Four integrated pillars — discovery, booking, wellness tracking, and smart '
    'reminders — work together so you never have to juggle multiple apps again.';

// ── Feature deep-dives ────────────────────────────────────────────────────────
const List<_FeatureDeep> kFeatureDeeps = [
  _FeatureDeep(
    icon:    Icons.person_search_rounded,
    eyebrow: 'Trainer Discovery',
    title:   'Find the right trainer,\nnot just any trainer.',
    body:    'Browse a curated roster of certified Mombasa trainers, each with a '
             'detailed profile covering specialties, pricing, availability windows, '
             'and verified client reviews. Filter by discipline — strength, yoga, HIIT, '
             'swimming, boxing, rehabilitation — and surface exactly who fits your '
             'schedule and goals.\n\n'
             'Every trainer profile includes certification details, session formats '
             '(in-gym, outdoor, virtual), and a live availability calendar so you '
             'know when they\'re free before you even click.',
    bullets: [
      'Specialty filters: 10+ disciplines',
      'Verified certifications on every profile',
      'Location-aware results via Mapbox',
      'Real-time availability displayed upfront',
    ],
    accentColor: 0, // primary
  ),
  _FeatureDeep(
    icon:    Icons.event_available_rounded,
    eyebrow: 'Booking System',
    title:   'From browsing to booked\nin under thirty seconds.',
    body:    'WellPath\'s booking engine is built on an atomic Firestore transaction — '
             'meaning two people can never book the same slot simultaneously. Tap an '
             'available slot, confirm your booking, and receive a push notification '
             'within seconds on both sides.\n\n'
             'Trainers manage their bookings from a dedicated dashboard: confirm, '
             'reschedule, or cancel with a single tap. Every change triggers '
             'automatic notifications so no one is ever left wondering.',
    bullets: [
      'Atomic booking — no double-booking, ever',
      'Instant push confirmation for user and trainer',
      'Trainer dashboard: confirm, cancel, reschedule',
      '24-hour session reminder for both parties',
    ],
    accentColor: 1, // secondary
  ),
  _FeatureDeep(
    icon:    Icons.insights_rounded,
    eyebrow: 'Wellness Tracking',
    title:   'Three logs. One dashboard.\nThe full picture.',
    body:    'Log workouts, daily water intake, and sleep from the same screen. '
             'The weekly dashboard plots your data across a seven-day calendar, '
             'highlights streaks, and compares actuals against your personal goals.\n\n'
             'Goal setting is simple: choose a target for workouts per week, '
             'daily hydration, and sleep hours. An animated progress ring shows '
             'where you stand at a glance. Offline logging is fully supported — '
             'your data syncs when connectivity returns.',
    bullets: [
      'Three log types: workout, water, sleep',
      'Weekly dashboard with 7-day calendar view',
      'Animated goal progress rings',
      'Offline-first — syncs when back online',
    ],
    accentColor: 0, // primary
  ),
  _FeatureDeep(
    icon:    Icons.notifications_active_rounded,
    eyebrow: 'Smart Reminders',
    title:   'The right nudge at\nthe right moment.',
    body:    'WellPath\'s notification layer is built on Firebase Cloud Messaging '
             'and runs across browser, Android, and iOS. Booking confirmations '
             'fire instantly. Session reminders go out 24 hours before your next '
             'appointment. A daily wellness prompt checks in on your water and '
             'sleep goals at a time you choose.\n\n'
             'Every notification category is individually toggleable from the '
             'Notification Settings screen — so you stay informed without ever '
             'feeling overwhelmed.',
    bullets: [
      'Instant booking push for user and trainer',
      '24-hour pre-session reminders',
      'Daily wellness check-in at your chosen time',
      'Granular per-category notification controls',
    ],
    accentColor: 1, // secondary
  ),
];

// ── Upcoming section ──────────────────────────────────────────────────────────
const List<_UpcomingItem> kUpcoming = [
  _UpcomingItem(label: 'Group class booking'),
  _UpcomingItem(label: 'Nutrition logging'),
  _UpcomingItem(label: 'Progress photo timeline'),
  _UpcomingItem(label: 'Trainer video consultations'),
  _UpcomingItem(label: 'Gym & facility finder'),
  _UpcomingItem(label: 'In-app messaging'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureDeep {
  final IconData     icon;
  final String       eyebrow;
  final String       title;
  final String       body;
  final List<String> bullets;
  final int          accentColor; // 0 = primary, 1 = secondary
  const _FeatureDeep({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.bullets,
    required this.accentColor,
  });
}

class _UpcomingItem {
  final String label;
  const _UpcomingItem({required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// FeaturesScreen
// ─────────────────────────────────────────────────────────────────────────────

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        AppCanvas(
          type:          BackgroundType.meshParticle,
          particleStyle: ParticleStyle.drift,
          gradientStyle: GradientStyle.pulse,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kFeaturesMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kFeaturesPaddingH,
                    vertical:   kFeaturesPaddingV,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        AppNavBar(
                          navItems:       kMarketingNavItems,
                          logoSize:       LogoSize.lg,
                          ctaLabel:       'Get Started →',
                          onCta:          () => context.push('/signup'),
                          onProfileTap:   () => context.push('/login'),
                          profileIcon:    Icons.person_outline,
                          profileTooltip: 'Sign in or create an account',
                          fullWidth:      true,
                        ),

                        SizedBox(height: AppSpacing.xxl),

                        // ── Page hero ────────────────────────────────────────
                        const _FeaturesHero(),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                        // ── Feature deep-dives ───────────────────────────────
                        ...kFeatureDeeps.asMap().entries.map((entry) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.xxl + AppSpacing.lg),
                            child: _FeatureDeepSection(
                              feature: entry.value,
                              flip:    entry.key.isOdd,
                            ),
                          );
                        }),

                        // ── Upcoming features ────────────────────────────────
                        const _UpcomingSection(),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                        // ── CTA strip ────────────────────────────────────────
                        _FeaturesCta(onTap: () => context.push('/signup')),

                        SizedBox(height: AppSpacing.xxl),

                        // ── Footer ───────────────────────────────────────────
                        const _FeaturesFooter(),

                        SizedBox(height: kFabSize + kFabMarginBottom + AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          right:  kFabMarginRight,
          bottom: kFabMarginBottom,
          child: AppFab(
            icon:    Icons.chat_bubble_outline,
            label:   'Feedback',
            tooltip: 'Chat with our AI assistant — share feedback or ideas',
            onPressed: () => showDialog(
              context:            context,
              barrierColor:       AppColors.scrim,
              barrierDismissible: true,
              builder: (_) => const DeveloperFeedbackChat(page: 'features'),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeaturesHero
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesHero extends StatelessWidget {
  const _FeaturesHero();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('PLATFORM FEATURES', style: AppTypography.overline),
      SizedBox(height: AppSpacing.md),
      ShaderMask(
        shaderCallback: (bounds) => AppGradients.button.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Text(
          kFeaturesHeadline,
          textAlign: TextAlign.center,
          style: AppTypography.h1.copyWith(
            fontSize:   44,
            height:     1.15,
            fontWeight: FontWeight.w800,
            color:      AppColors.textPrimary,
          ),
        ),
      ),
      SizedBox(height: AppSpacing.lg),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Text(
          kFeaturesSubline,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(height: 1.7, color: AppColors.textSecondary),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeatureDeepSection — alternating image-left / image-right layout
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureDeepSection extends StatelessWidget {
  final _FeatureDeep feature;
  final bool         flip; // true = copy left, visual right
  const _FeatureDeepSection({required this.feature, required this.flip});

  Color get _accent => feature.accentColor == 0 ? AppColors.primary : AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 720;
      final copyCol = _CopyColumn(feature: feature, accent: _accent);
      final visualCol = _VisualColumn(feature: feature, accent: _accent);

      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: flip
              ? [Expanded(child: copyCol), SizedBox(width: AppSpacing.xxl), Expanded(child: visualCol)]
              : [Expanded(child: visualCol), SizedBox(width: AppSpacing.xxl), Expanded(child: copyCol)],
        );
      } else {
        return Column(children: [
          visualCol,
          SizedBox(height: AppSpacing.xl),
          copyCol,
        ]);
      }
    });
  }
}

class _CopyColumn extends StatelessWidget {
  final _FeatureDeep feature;
  final Color        accent;
  const _CopyColumn({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Eyebrow chip
      Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color:        accent.withAlpha(20),
          borderRadius: AppRadius.pillBR,
          border:       Border.all(color: accent.withAlpha(50)),
        ),
        child: Text(
          feature.eyebrow.toUpperCase(),
          style: AppTypography.chip.copyWith(color: accent, fontSize: 10),
        ),
      ),
      SizedBox(height: AppSpacing.md),
      Text(feature.title,
          style: AppTypography.h2.copyWith(fontSize: 28, height: 1.2)),
      SizedBox(height: AppSpacing.md),
      Text(feature.body,
          style: AppTypography.body.copyWith(height: 1.8, color: AppColors.textSecondary)),
      SizedBox(height: AppSpacing.lg),
      // Bullet points
      ...feature.bullets.map((b) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width:  6, height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(b, style: AppTypography.bodySmall.copyWith(height: 1.5))),
        ]),
      )),
    ]);
  }
}

class _VisualColumn extends StatelessWidget {
  final _FeatureDeep feature;
  final Color        accent;
  const _VisualColumn({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: accent.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withAlpha(25), blurRadius: 40, spreadRadius: 2),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background glow
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBR,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [accent.withAlpha(15), Colors.transparent],
              ),
            ),
          ),
          // Icon centred
          Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color:        accent.withAlpha(20),
                  borderRadius: AppRadius.cardBR,
                ),
                child: Icon(feature.icon, size: 48, color: accent),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                feature.eyebrow,
                style: AppTypography.h5.copyWith(color: accent, fontSize: 15),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UpcomingSection
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text('COMING SOON', style: AppTypography.overline),
        SizedBox(height: AppSpacing.sm),
        Text('What\'s next on the roadmap',
            style: AppTypography.h3.copyWith(fontSize: 22)),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing:   AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: kUpcoming.map((item) => Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color:        AppColors.tint10(AppColors.secondary),
              borderRadius: AppRadius.pillBR,
              border:       Border.all(color: AppColors.tint20(AppColors.secondary)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule_rounded, size: 13, color: AppColors.secondary),
              SizedBox(width: AppSpacing.xs),
              Text(item.label,
                  style: AppTypography.chip.copyWith(color: AppColors.secondary, fontSize: 12)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeaturesCta
// ─────────────────────────────────────────────────────────────────────────────

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
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width:    double.infinity,
          padding:  EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient:     _hovered ? AppGradients.buttonHover : AppGradients.button,
            borderRadius: AppRadius.cardBR,
            boxShadow:    _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
          ),
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
                color:        AppColors.surface.withAlpha(60),
                borderRadius: AppRadius.pillBR,
                border:       Border.all(color: AppColors.borderStrong),
              ),
              child: Text('Create Free Account',
                  style: AppTypography.button.copyWith(fontSize: 15)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeaturesFooter
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesFooter extends StatelessWidget {
  const _FeaturesFooter();

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
              color: AppColors.primary, fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ]),
      SizedBox(height: AppSpacing.lg),
    ]);
  }
}