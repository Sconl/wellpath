// lib/spaces/space_site/pricing/pricing_screen.dart
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

const double kPricingMaxWidth = 1100.0;
const double kPricingPaddingH = 60.0;

const bool _kShowHeroAnimation = true;

const String kPricingStatic = 'Simple, honest pricing.';

const _TC kPricingTyping = TypingTextConfig(
  phrases: [
    'Simple, honest pricing.',
    'Start free.\nGrow with us.',
    'No hidden fees.\nNo long contracts.',
  ],
  fontSize: 48,
  headlineBlockHeight: 120,
);
typedef _TC = TypingTextConfig;

const String kPricingSubline =
    'Start free and upgrade when you\'re ready. No hidden fees, '
    'no long contracts — just the tools you need at a price that makes sense.';

const List<_PricingTier> kTiers = [
  _PricingTier(
    badge: null, name: 'Free', price: 'KES 0', period: 'forever',
    isHighlight: false, ctaLabel: 'Get Started Free', ctaRoute: '/signup',
    description: 'Everything you need to discover trainers and start your wellness journey.',
    features: [
      _TierFeature('Browse all certified trainers',             included: true),
      _TierFeature('Up to 3 bookings per month',               included: true),
      _TierFeature('Wellness logging (workout, water, sleep)',  included: true),
      _TierFeature('Weekly wellness dashboard',                included: true),
      _TierFeature('Booking confirmation notifications',       included: true),
      _TierFeature('Unlimited bookings',                       included: false),
      _TierFeature('Advanced goal tracking',                   included: false),
      _TierFeature('Priority trainer matching',                included: false),
    ],
  ),
  _PricingTier(
    badge: 'Most Popular', name: 'Pro', price: 'KES 499', period: 'per month',
    isHighlight: true, ctaLabel: 'Start Pro — 7 days free', ctaRoute: '/signup',
    description: 'Unlimited bookings, advanced tracking, and priority support.',
    features: [
      _TierFeature('Browse all certified trainers',                included: true),
      _TierFeature('Unlimited bookings',                           included: true),
      _TierFeature('Wellness logging (workout, water, sleep)',     included: true),
      _TierFeature('Advanced goal tracking + streaks',             included: true),
      _TierFeature('Full push notification suite',                 included: true),
      _TierFeature('Priority trainer matching',                    included: true),
      _TierFeature('Export wellness data (CSV)',                   included: true),
      _TierFeature('Early access to new features',                 included: true),
    ],
  ),
  _PricingTier(
    badge: 'For Trainers', name: 'Trainer', price: 'KES 299', period: 'per month',
    isHighlight: false, ctaLabel: 'Join as a Trainer', ctaRoute: '/signup',
    description: 'A professional profile, full booking management, and client growth tools.',
    features: [
      _TierFeature('Verified trainer profile',               included: true),
      _TierFeature('Availability management calendar',       included: true),
      _TierFeature('Client booking dashboard',               included: true),
      _TierFeature('Booking confirm / cancel / reschedule',  included: true),
      _TierFeature('Push notifications for new bookings',    included: true),
      _TierFeature('Client review & rating visibility',      included: true),
      _TierFeature('Analytics: views, bookings, conversion', included: true),
      _TierFeature('Featured placement (coming soon)',       included: false),
    ],
  ),
];

const List<_FaqItem> kFaq = [
  _FaqItem('Is the Free plan really free forever?',
    'Yes. The Free plan has no time limit. You can browse trainers, make up to '
    '3 bookings per month, and log your wellness data indefinitely at no cost.'),
  _FaqItem('How does the 7-day Pro trial work?',
    'When you sign up for Pro, your first 7 days are free. You won\'t be charged '
    'until the trial ends, and you can cancel any time before then.'),
  _FaqItem('Can I switch between plans?',
    'Absolutely. You can upgrade, downgrade, or cancel from your account settings '
    'at any time. Downgrades take effect at the end of your current billing period.'),
  _FaqItem('What payment methods do you accept?',
    'M-Pesa, Visa, Mastercard, and major Kenyan debit cards. All transactions '
    'are processed securely through Stripe.'),
  _FaqItem('How does the Trainer plan work?',
    'Trainers create a profile, set their availability, and receive booking requests. '
    'You control your schedule completely — accept, decline, or reschedule any booking.'),
  _FaqItem('Is my data safe?',
    'WellPath stores all user data in Firebase Firestore with strict security rules. '
    'Wellness logs and booking data are private by default.'),
];

class _PricingTier {
  final String? badge; final String name; final String price;
  final String period; final bool isHighlight; final String ctaLabel;
  final String ctaRoute; final String description;
  final List<_TierFeature> features;
  const _PricingTier({required this.badge, required this.name, required this.price,
    required this.period, required this.isHighlight, required this.ctaLabel,
    required this.ctaRoute, required this.description, required this.features});
}
class _TierFeature {
  final String label; final bool included;
  const _TierFeature(this.label, {required this.included});
}
class _FaqItem {
  final String question; final String answer;
  const _FaqItem(this.question, this.answer);
}

// ─────────────────────────────────────────────────────────────────────────────
// PricingScreen
// ─────────────────────────────────────────────────────────────────────────────

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
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
                constraints: const BoxConstraints(maxWidth: kPricingMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: kPricingPaddingH),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      SizedBox(height: kMarketingNavBarHeight),
                      SizedBox(height: AppSpacing.xxl),

                      SitePageHero(
                        eyebrow:        'Pricing',
                        staticHeadline: kPricingStatic,
                        subline:        kPricingSubline,
                        typingConfig:   kPricingTyping,
                        showAnimation:  _kShowHeroAnimation,
                      ),

                      SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

                      _PricingCards(),

                      SizedBox(height: AppSpacing.xl),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textMuted),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Secure payments via M-Pesa & Stripe · Cancel anytime · No hidden fees',
                          style: AppTypography.caption.copyWith(fontSize: 12)),
                      ]),

                      SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                      _FaqSection(),
                      SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                      _PricingFinalCta(onTap: () => context.push('/signup')),
                      SizedBox(height: AppSpacing.xxl),
                      _PricingFooter(),
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
            tooltip: 'Chat with our AI assistant',
            onPressed: () => showDialog(context: context, barrierColor: AppColors.scrim,
              barrierDismissible: true,
              builder: (_) => const DeveloperFeedbackChat(page: 'pricing')),
          ),
        ),
      ]),
    );
  }
}

class _PricingCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 800;
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: kTiers.asMap().entries.map((e) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: e.key == kTiers.length - 1 ? 0 : AppSpacing.md),
            child: _PricingCard(tier: e.value),
          ))).toList());
      }
      return Column(children: kTiers.map((t) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: _PricingCard(tier: t),
      )).toList());
    });
  }
}

class _PricingCard extends StatefulWidget {
  final _PricingTier tier;
  const _PricingCard({required this.tier});

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tier;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedGradientBorder(
        isActive:     t.isHighlight ? false : _hovered,
        borderRadius: AppRadius.cardBR,
        showStaticBorder: false,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.all(AppSpacing.xl),
          transform: Matrix4.translationValues(0, _hovered && !t.isHighlight ? -4 : 0, 0),
          decoration: BoxDecoration(
            gradient:     t.isHighlight ? AppGradients.surface : null,
            color:        t.isHighlight ? null : AppColors.surface,
            borderRadius: AppRadius.cardBR,
            border: t.isHighlight
                ? Border.all(color: AppColors.primary, width: 1.5)
                : Border.all(color: _hovered ? AppColors.primary.withAlpha(120) : AppColors.border,
                    width: _hovered ? 1.5 : 1.0),
            boxShadow: t.isHighlight
                ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 32, spreadRadius: 2)]
                : _hovered
                    ? [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 20)]
                    : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (t.badge != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: t.isHighlight ? AppGradients.button : null,
                  color:    t.isHighlight ? null : AppColors.tint10(AppColors.secondary),
                  borderRadius: AppRadius.pillBR,
                  border: t.isHighlight ? null : Border.all(color: AppColors.tint20(AppColors.secondary))),
                child: Text(t.badge!, style: AppTypography.chip.copyWith(
                  color: t.isHighlight ? AppColors.onPrimary : AppColors.secondary,
                  fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(height: AppSpacing.md),
            ],
            Text(t.name, style: AppTypography.h3.copyWith(fontSize: 22)),
            SizedBox(height: AppSpacing.sm),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(t.price, style: AppTypography.h1.copyWith(
                fontSize: 34, fontWeight: FontWeight.w800, height: 1,
                color: t.isHighlight ? AppColors.primary : AppColors.textPrimary)),
              SizedBox(width: AppSpacing.xs),
              Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Text('/ ${t.period}', style: AppTypography.caption.copyWith(fontSize: 12))),
            ]),
            SizedBox(height: AppSpacing.sm),
            Text(t.description, style: AppTypography.bodySmall.copyWith(height: 1.55, fontSize: 13)),
            SizedBox(height: AppSpacing.xl),
            ...t.features.map((f) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Row(children: [
                Icon(f.included ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                  size: 18, color: f.included ? AppColors.success : AppColors.textMuted),
                SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(f.label, style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  color: f.included ? AppColors.textPrimary : AppColors.textMuted))),
              ]),
            )),
            SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => context.push(t.ctaRoute),
              child: AnimatedContainer(
                duration: AppDurations.fast, width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient:     t.isHighlight ? AppGradients.button : null,
                  color:        t.isHighlight ? null : Colors.transparent,
                  borderRadius: AppRadius.pillBR,
                  border: t.isHighlight ? null : Border.all(color: AppColors.borderStrong),
                  boxShadow:    t.isHighlight ? AppShadows.buttonGlow : null),
                child: Text(t.ctaLabel, textAlign: TextAlign.center,
                  style: AppTypography.button.copyWith(
                    fontSize: 14,
                    color: t.isHighlight ? AppColors.onPrimary : AppColors.textSecondary)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow: 'FAQ',
        headline: 'Common questions',
      ),
      SizedBox(height: AppSpacing.xxl),
      ...kFaq.map((item) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: _FaqTile(item: item))),
    ]);
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: AppDurations.normal, padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color:        _expanded ? AppColors.surfaceMid : AppColors.surface,
            borderRadius: AppRadius.cardBR,
            border: Border.all(
                color: _expanded ? AppColors.primary : AppColors.border,
                width: _expanded ? 1.5 : 1.0)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(widget.item.question,
                  style: AppTypography.h5.copyWith(fontSize: 15))),
              SizedBox(width: AppSpacing.md),
              AnimatedRotation(
                duration: AppDurations.fast, turns: _expanded ? 0.5 : 0,
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 22,
                    color: _expanded ? AppColors.primary : AppColors.textMuted)),
            ]),
            AnimatedSize(
              duration: AppDurations.normal, curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(padding: EdgeInsets.only(top: AppSpacing.md),
                      child: Text(widget.item.answer,
                          style: AppTypography.bodySmall.copyWith(height: 1.7)))
                  : const SizedBox.shrink()),
          ]),
        ),
      ),
    );
  }
}

class _PricingFinalCta extends StatelessWidget {
  final VoidCallback onTap;
  const _PricingFinalCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: AppRadius.cardBR,
        border: Border.all(color: AppColors.borderStrong)),
      child: Column(children: [
        SiteSectionHeader(
          eyebrow:  'Get Started',
          headline: 'Start free. Upgrade when ready.',
          subline:  'No commitment required. Your first bookings are on us.',
          headlineFontSize: 28,
          maxSublineWidth: 400,
        ),
        SizedBox(height: AppSpacing.xl),
        PrimaryAttentionButton(
          label: 'Create Free Account', onTap: onTap,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
          fontSize: 15,
        ),
      ]),
    );
  }
}

class _PricingFooter extends StatelessWidget {
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
                  color: AppColors.primary, fontWeight: FontWeight.w500))),
      ]),
      SizedBox(height: AppSpacing.lg),
    ]);
  }
}