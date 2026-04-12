// lib/features/about/presentation/about_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// WellPath — About page.
// Public marketing screen. No auth required.
// Covers: mission, origin story, values, technology stack.
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

const double kAboutMaxWidth  = 1100.0;
const double kAboutPaddingH  = 60.0;
const double kAboutPaddingV  = 32.0;

// Mission
const String kMissionHeadline = 'Fitness should be\naccessible to everyone.';
const String kMissionBody =
    'WellPath was built on a simple belief: that connecting with a great trainer, '
    'staying consistent, and tracking your progress should be effortless — regardless '
    'of where you live or who you are. We started in Mombasa, Kenya, because we '
    'believe world-class wellness infrastructure deserves to be local.';

// Story
const String kStoryHeadline = 'Where we come from';
const String kStoryBody =
    'WellPath began as a final-year research project at the Department of Information '
    'Technology, exploring what a modern, web-based integrated fitness and wellness '
    'platform could look like when built with a real community in mind.\n\n'
    'The case study centred on Mombasa — a city rich with active people, talented '
    'trainers, and vibrant fitness culture, but underserved by the digital tools that '
    'connect them. Ten weeks of sprint development later, WellPath went from a concept '
    'canvas to a live, full-stack Flutter web application backed by Firebase.\n\n'
    'Every design decision, every data model, and every notification flow was shaped '
    'by the real needs of Mombasa\'s fitness community.';

// Values
const List<_ValueItem> kValues = [
  _ValueItem(
    icon:  Icons.people_alt_rounded,
    title: 'Community First',
    body:  'We build for real people in real places. Mombasa is our home, and every '
           'feature reflects the rhythms and needs of this community.',
  ),
  _ValueItem(
    icon:  Icons.verified_rounded,
    title: 'Quality & Trust',
    body:  'Every trainer on WellPath is reviewed and verified. We maintain high '
           'standards because your health deserves nothing less.',
  ),
  _ValueItem(
    icon:  Icons.bolt_rounded,
    title: 'Relentless Simplicity',
    body:  'Booking a session should take two taps. Logging a workout should take '
           'thirty seconds. We obsess over removing friction.',
  ),
];

// Tech stack
const List<_TechItem> kTechStack = [
  _TechItem(label: 'Flutter Web',      sublabel: 'Cross-platform UI'),
  _TechItem(label: 'Firebase',         sublabel: 'Auth, Firestore, Hosting'),
  _TechItem(label: 'Cloud Functions',  sublabel: 'Serverless backend logic'),
  _TechItem(label: 'Riverpod',         sublabel: 'State management'),
  _TechItem(label: 'GoRouter',         sublabel: 'Navigation & deep links'),
  _TechItem(label: 'Mapbox',           sublabel: 'Trainer location mapping'),
  _TechItem(label: 'FCM',              sublabel: 'Push notifications'),
  _TechItem(label: 'Firebase Analytics', sublabel: 'Usage insights'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

class _ValueItem {
  final IconData icon;
  final String   title;
  final String   body;
  const _ValueItem({required this.icon, required this.title, required this.body});
}

class _TechItem {
  final String label;
  final String sublabel;
  const _TechItem({required this.label, required this.sublabel});
}

// ─────────────────────────────────────────────────────────────────────────────
// AboutScreen
// ─────────────────────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                constraints: const BoxConstraints(maxWidth: kAboutMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kAboutPaddingH,
                    vertical:   kAboutPaddingV,
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

                        // ── Hero ────────────────────────────────────────────
                        const _AboutHero(),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                        // ── Story ────────────────────────────────────────────
                        const _StorySection(),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                        // ── Values ───────────────────────────────────────────
                        const _ValuesSection(),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                        // ── Tech stack ────────────────────────────────────────
                        const _TechStackSection(),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                        // ── Author card ───────────────────────────────────────
                        const _AuthorCard(),

                        SizedBox(height: AppSpacing.xxl),

                        // ── Footer ────────────────────────────────────────────
                        const _AboutFooter(),

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
              builder: (_) => const DeveloperFeedbackChat(page: 'about'),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AboutHero
// ─────────────────────────────────────────────────────────────────────────────

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('ABOUT WELLPATH', style: AppTypography.overline),
      SizedBox(height: AppSpacing.md),
      ShaderMask(
        shaderCallback: (bounds) => AppGradients.button.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Text(
          kMissionHeadline,
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
        constraints: const BoxConstraints(maxWidth: 680),
        child: Text(
          kMissionBody,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(height: 1.75, color: AppColors.textSecondary),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StorySection
// ─────────────────────────────────────────────────────────────────────────────

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: label column
            SizedBox(
              width: 240,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('OUR STORY', style: AppTypography.overline),
                  SizedBox(height: AppSpacing.sm),
                  Text(kStoryHeadline,
                      style: AppTypography.h3.copyWith(fontSize: 22, height: 1.3)),
                  SizedBox(height: AppSpacing.md),
                  Container(width: 40, height: 3,
                      decoration: BoxDecoration(
                        gradient:     AppGradients.button,
                        borderRadius: BorderRadius.circular(2),
                      )),
                ]),
              ),
            ),
            SizedBox(width: AppSpacing.xxl),
            // Right: body text
            Expanded(child: Text(
              kStoryBody,
              style: AppTypography.body.copyWith(height: 1.85, color: AppColors.textSecondary),
            )),
          ],
        );
      } else {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('OUR STORY', style: AppTypography.overline),
          SizedBox(height: AppSpacing.sm),
          Text(kStoryHeadline, style: AppTypography.h3.copyWith(fontSize: 22, height: 1.3)),
          SizedBox(height: AppSpacing.lg),
          Text(kStoryBody, style: AppTypography.body.copyWith(height: 1.85, color: AppColors.textSecondary)),
        ]);
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ValuesSection
// ─────────────────────────────────────────────────────────────────────────────

class _ValuesSection extends StatelessWidget {
  const _ValuesSection();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('OUR VALUES', style: AppTypography.overline),
      SizedBox(height: AppSpacing.sm),
      Text('What we stand for', style: AppTypography.h2.copyWith(fontSize: 32)),
      SizedBox(height: AppSpacing.xxl),
      LayoutBuilder(builder: (_, constraints) {
        final wide = constraints.maxWidth > 700;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: kValues.asMap().entries.map((entry) {
              final isLast = entry.key == kValues.length - 1;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.md),
                child: _ValueCard(value: entry.value),
              ));
            }).toList(),
          );
        } else {
          return Column(children: kValues.map((v) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _ValueCard(value: v),
          )).toList());
        }
      }),
    ]);
  }
}

class _ValueCard extends StatefulWidget {
  final _ValueItem value;
  const _ValueCard({required this.value});

  @override
  State<_ValueCard> createState() => _ValueCardState();
}

class _ValueCardState extends State<_ValueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding:  EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color:        _hovered ? AppColors.surfaceMid : AppColors.surface,
          borderRadius: AppRadius.cardBR,
          border: Border.all(
            color: _hovered ? AppColors.primary : AppColors.border,
            width: _hovered ? 1.5 : 1.0,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color:        AppColors.tint10(AppColors.primary),
              borderRadius: AppRadius.cardBR,
            ),
            child: Icon(widget.value.icon, size: 24, color: AppColors.primary),
          ),
          SizedBox(height: AppSpacing.md),
          Text(widget.value.title, style: AppTypography.h4.copyWith(fontSize: 17)),
          SizedBox(height: AppSpacing.sm),
          Text(widget.value.body,
              style: AppTypography.bodySmall.copyWith(height: 1.65)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TechStackSection
// ─────────────────────────────────────────────────────────────────────────────

class _TechStackSection extends StatelessWidget {
  const _TechStackSection();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('BUILT WITH', style: AppTypography.overline),
      SizedBox(height: AppSpacing.sm),
      Text('Technology stack', style: AppTypography.h2.copyWith(fontSize: 32)),
      SizedBox(height: AppSpacing.sm),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Text(
          'A modern, scalable stack designed for real-world performance on any device.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(height: 1.6),
        ),
      ),
      SizedBox(height: AppSpacing.xxl),
      Wrap(
        spacing:    AppSpacing.md,
        runSpacing: AppSpacing.md,
        alignment:  WrapAlignment.center,
        children: kTechStack.map((t) => _TechChip(tech: t)).toList(),
      ),
    ]);
  }
}

class _TechChip extends StatefulWidget {
  final _TechItem tech;
  const _TechChip({required this.tech});

  @override
  State<_TechChip> createState() => _TechChipState();
}

class _TechChipState extends State<_TechChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md + 4, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color:        _hovered ? AppColors.tint10(AppColors.primary) : AppColors.surface,
          borderRadius: AppRadius.cardBR,
          border: Border.all(
            color: _hovered ? AppColors.primary : AppColors.border,
            width: _hovered ? 1.5 : 1.0,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            widget.tech.label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SizedBox(height: AppSpacing.xs - 1),
          Text(widget.tech.sublabel, style: AppTypography.caption.copyWith(fontSize: 11)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthorCard
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient:     AppGradients.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.borderStrong),
      ),
      child: LayoutBuilder(builder: (_, constraints) {
        final wide = constraints.maxWidth > 500;
        final content = [
          // Avatar
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient:    AppGradients.button,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text('GM',
                style: AppTypography.h3.copyWith(
                  color: AppColors.onPrimary, fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: wide ? AppSpacing.lg : 0, height: wide ? 0 : AppSpacing.md),
          Flexible(child: Column(
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text('Grace Miriri',
                  style: AppTypography.h3.copyWith(fontSize: 20)),
              SizedBox(height: AppSpacing.xs),
              Text('BSIT/445J/2020 · Department of Information Technology',
                  style: AppTypography.bodySmall.copyWith(fontSize: 13)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'WellPath is the culmination of ten weeks of full-stack development, '
                'user research, and design work — a living case study in building '
                'wellness technology that serves real communities.',
                style: AppTypography.bodySmall.copyWith(height: 1.65),
              ),
            ],
          )),
        ];
        return wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: content)
            : Column(crossAxisAlignment: CrossAxisAlignment.center, children: content);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AboutFooter
// ─────────────────────────────────────────────────────────────────────────────

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

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