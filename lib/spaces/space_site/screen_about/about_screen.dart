// lib/spaces/space_site/about/about_screen.dart
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

const double kAboutMaxWidth = 1100.0;
const double kAboutPaddingH = 60.0;

// Toggle animated hero title. Set false to show staticHeadline only.
const bool _kShowHeroAnimation = true;

const String kMissionStatic =
    'Fitness should be\naccessible to everyone.';

const _TypingTextConfig kAboutTyping = TypingTextConfig(
  phrases: [
    'Fitness should be\naccessible to everyone.',
    'Built for Mombasa.\nBuilt to last.',
    'Our story,\nour mission.',
  ],
  fontSize: 44,
  headlineBlockHeight: 110,
);

const String kMissionBody =
    'WellPath was built on a simple belief: that connecting with a great trainer, '
    'staying consistent, and tracking your progress should be effortless — regardless '
    'of where you live or who you are. We started in Mombasa, Kenya, because we '
    'believe world-class wellness infrastructure deserves to be local.';

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

const List<_ValueItem> kValues = [
  _ValueItem(icon: Icons.people_alt_rounded, title: 'Community First',
    body: 'We build for real people in real places. Mombasa is our home, and every '
          'feature reflects the rhythms and needs of this community.'),
  _ValueItem(icon: Icons.verified_rounded, title: 'Quality & Trust',
    body: 'Every trainer on WellPath is reviewed and verified. We maintain high '
          'standards because your health deserves nothing less.'),
  _ValueItem(icon: Icons.bolt_rounded, title: 'Relentless Simplicity',
    body: 'Booking a session should take two taps. Logging a workout should take '
          'thirty seconds. We obsess over removing friction.'),
];

const List<_TechItem> kTechStack = [
  _TechItem(label: 'Flutter Web',        sublabel: 'Cross-platform UI'),
  _TechItem(label: 'Firebase',           sublabel: 'Auth, Firestore, Hosting'),
  _TechItem(label: 'Cloud Functions',    sublabel: 'Serverless backend logic'),
  _TechItem(label: 'Riverpod',           sublabel: 'State management'),
  _TechItem(label: 'GoRouter',           sublabel: 'Navigation & deep links'),
  _TechItem(label: 'Mapbox',             sublabel: 'Trainer location mapping'),
  _TechItem(label: 'FCM',                sublabel: 'Push notifications'),
  _TechItem(label: 'Firebase Analytics', sublabel: 'Usage insights'),
];

class _ValueItem {
  final IconData icon; final String title; final String body;
  const _ValueItem({required this.icon, required this.title, required this.body});
}
class _TechItem {
  final String label; final String sublabel;
  const _TechItem({required this.label, required this.sublabel});
}

// Alias to avoid confusion with app_motion export
typedef _TypingTextConfig = TypingTextConfig;

// ─────────────────────────────────────────────────────────────────────────────
// AboutScreen
// ─────────────────────────────────────────────────────────────────────────────

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        AppCanvas(
          type: BackgroundType.meshParticle,
          particleStyle: ParticleStyle.drift,
          gradientStyle: GradientStyle.pulse,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kAboutMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: kAboutPaddingH),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: kMarketingNavBarHeight),
                        SizedBox(height: AppSpacing.xxl),

                        SitePageHero(
                          eyebrow:        'About WellPath',
                          staticHeadline: kMissionStatic,
                          subline:        kMissionBody,
                          typingConfig:   kAboutTyping,
                          showAnimation:  _kShowHeroAnimation,
                        ),

                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                        _StorySection(),
                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                        _ValuesSection(),
                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                        _TechStackSection(),
                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                        _AuthorCard(),
                        SizedBox(height: AppSpacing.xxl),
                        _AboutFooter(),
                        SizedBox(height: kFabSize + kFabMarginBottom + AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        MarketingTopNav(
          navItems:         kDefaultMarketingNavItems,
          ctaLabel:         'Get Started →',
          scrollController: _scrollCtrl,
          onCta:            () => context.push('/signup'),
          onProfileTap:     () => context.push('/login'),
        ),

        Positioned(
          right: kFabMarginRight, bottom: kFabMarginBottom,
          child: AppFab(
            icon: Icons.chat_bubble_outline, label: 'Feedback',
            tooltip: 'Chat with our AI assistant — share feedback or ideas',
            onPressed: () => showDialog(
              context: context, barrierColor: AppColors.scrim,
              barrierDismissible: true,
              builder: (_) => const DeveloperFeedbackChat(page: 'about')),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 240, child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('OUR STORY', style: AppTypography.overline),
              SizedBox(height: AppSpacing.sm),
              Text(kStoryHeadline,
                  style: AppTypography.h3.copyWith(fontSize: 22, height: 1.3)),
              SizedBox(height: AppSpacing.md),
              Container(width: 40, height: 3, decoration: BoxDecoration(
                gradient: AppGradients.button, borderRadius: BorderRadius.circular(2))),
            ]),
          )),
          SizedBox(width: AppSpacing.xxl),
          Expanded(child: Text(kStoryBody,
              style: AppTypography.body.copyWith(height: 1.85, color: AppColors.textSecondary))),
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OUR STORY', style: AppTypography.overline),
        SizedBox(height: AppSpacing.sm),
        Text(kStoryHeadline, style: AppTypography.h3.copyWith(fontSize: 22, height: 1.3)),
        SizedBox(height: AppSpacing.lg),
        Text(kStoryBody, style: AppTypography.body.copyWith(height: 1.85, color: AppColors.textSecondary)),
      ]);
    });
  }
}

class _ValuesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow: 'Our Values',
        headline: 'What we stand for',
      ),
      SizedBox(height: AppSpacing.xxl),
      LayoutBuilder(builder: (_, constraints) {
        final wide = constraints.maxWidth > 700;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: kValues.asMap().entries.map((e) => Expanded(child: Padding(
              padding: EdgeInsets.only(right: e.key == kValues.length - 1 ? 0 : AppSpacing.md),
              child: _ValueCard(value: e.value),
            ))).toList(),
          );
        }
        return Column(children: kValues.map((v) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _ValueCard(value: v),
        )).toList());
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
      child: AnimatedGradientBorder(
        isActive:     _hovered,
        borderRadius: AppRadius.cardBR,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding:  EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color:        _hovered ? AppColors.surfaceMid : AppColors.surface,
            borderRadius: AppRadius.cardBR,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.tint10(AppColors.primary),
                borderRadius: AppRadius.cardBR),
              child: Icon(widget.value.icon, size: 24, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.md),
            Text(widget.value.title, style: AppTypography.h4.copyWith(fontSize: 17)),
            SizedBox(height: AppSpacing.sm),
            Text(widget.value.body, style: AppTypography.bodySmall.copyWith(height: 1.65)),
          ]),
        ),
      ),
    );
  }
}

class _TechStackSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow:  'Built With',
        headline: 'Technology stack',
        subline:  'A modern, scalable stack designed for real-world performance on any device.',
        maxSublineWidth: 480,
      ),
      SizedBox(height: AppSpacing.xxl),
      Wrap(
        spacing: AppSpacing.md, runSpacing: AppSpacing.md,
        alignment: WrapAlignment.center,
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
          Text(widget.tech.label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
          SizedBox(height: AppSpacing.xs - 1),
          Text(widget.tech.sublabel, style: AppTypography.caption.copyWith(fontSize: 11)),
        ]),
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedGradientSurface(
      borderRadius: AppRadius.cardBR,
      border:       Border.all(color: AppColors.borderStrong),
      colors:       [AppColors.surfaceLit, AppColors.surfaceMid, AppColors.surface],
      duration:     const Duration(seconds: 8),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: LayoutBuilder(builder: (_, constraints) {
          final wide = constraints.maxWidth > 500;
          final avatar = Container(
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: AppGradients.button, borderRadius: BorderRadius.circular(32)),
            child: Center(child: Text('GM', style: AppTypography.h3.copyWith(
                color: AppColors.onPrimary, fontWeight: FontWeight.w800))),
          );
          final content = Column(
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text('Grace Miriri', style: AppTypography.h3.copyWith(fontSize: 20)),
              SizedBox(height: AppSpacing.xs),
              Text('BSIT/445J/2020 · Department of Information Technology',
                  style: AppTypography.bodySmall.copyWith(fontSize: 13)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'WellPath is the culmination of ten weeks of full-stack development, '
                'user research, and design work — a living case study in building '
                'wellness technology that serves real communities.',
                style: AppTypography.bodySmall.copyWith(height: 1.65)),
            ],
          );
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  avatar, SizedBox(width: AppSpacing.lg), Flexible(child: content)])
              : Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  avatar, SizedBox(height: AppSpacing.md), content]);
        }),
      ),
    );
  }
}

class _AboutFooter extends StatelessWidget {
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