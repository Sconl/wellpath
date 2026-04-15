// lib/spaces/space_admin/screens/screen_admin_features.dart
//
// QP CANON: space_admin › screen_admin_features
// Boolean section visibility, motion, and animation toggles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/admin/admin_state.dart';
import '../../../core/admin/q_admin_form.dart';

class ScreenAdminFeatures extends ConsumerWidget {
  const ScreenAdminFeatures({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(adminDraftProvider).flags;
    final n     = ref.read(adminDraftProvider.notifier);

    void toggle(bool Function(bool) updater, String field) {
      // Use copyWith via the notifier's toggleFlag helper
      n.updateFlags(flags);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('Features', style: AppTypography.h2.copyWith(fontSize: 22)),
        SizedBox(height: AppSpacing.xs),
        Text('Toggle sections and motion controls · path: space_site.screen_home.flags',
            style: AppTypography.caption.copyWith(fontSize: 11)),
        SizedBox(height: AppSpacing.xl),

        // ── Section visibility ─────────────────────────────────────────────
        AdminSectionCard(
          title: 'Section Visibility',
          icon:  Icons.layers_outlined,
          subtitle: '· flags.show*',
          child: Column(children: [
            AdminToggle(
              label:        'Trusted strip',
              manifestPath: 'flags.showTrustedStrip',
              description:  'Logo marquee below the hero CTA',
              value:        flags.showTrustedStrip,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showTrustedStrip: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Stats section',
              manifestPath: 'flags.showStats',
              description:  'Count-up metrics below trusted strip',
              value:        flags.showStats,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showStats: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Steps section',
              manifestPath: 'flags.showSteps',
              description:  'How it works — 3-step cards',
              value:        flags.showSteps,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showSteps: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Feature cards',
              manifestPath: 'flags.showFeatureCards',
              description:  'Platform feature highlight grid',
              value:        flags.showFeatureCards,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showFeatureCards: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Testimonials',
              manifestPath: 'flags.showTestimonials',
              description:  'Member quote cards',
              value:        flags.showTestimonials,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showTestimonials: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'CTA banner',
              manifestPath: 'flags.showCtaBanner',
              description:  'Animated gradient section_connect CTA',
              value:        flags.showCtaBanner,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showCtaBanner: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Feedback FAB',
              manifestPath: 'flags.showFab',
              description:  'Floating feedback chat button',
              value:        flags.showFab,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showFab: v)),
            ),
          ]),
        ),

        // ── Motion ────────────────────────────────────────────────────────
        AdminSectionCard(
          title: 'Motion',
          icon:  Icons.animation_outlined,
          subtitle: '· flags.enable*',
          initiallyExpanded: false,
          child: Column(children: [
            AdminToggle(
              label:        'Parallax scrolling',
              manifestPath: 'flags.enableParallax',
              description:  'Background moves at 30% scroll speed',
              value:        flags.enableParallax,
              onChanged:    (v) => n.updateFlags(flags.copyWith(enableParallax: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Depth mesh overlay',
              manifestPath: 'flags.enableDepthMesh',
              description:  'Subtle radial zones that enhance parallax depth',
              value:        flags.enableDepthMesh,
              onChanged:    (v) => n.updateFlags(flags.copyWith(enableDepthMesh: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Typing animation (hero)',
              manifestPath: 'flags.enableTypingAnimation',
              description:  'Phrase cycling in the hero headline',
              value:        flags.enableTypingAnimation,
              onChanged:    (v) => n.updateFlags(flags.copyWith(enableTypingAnimation: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Card border animation',
              manifestPath: 'flags.enableCardBorderAnimation',
              description:  'Gradient arc on hover for step, feature, and testimonial cards',
              value:        flags.enableCardBorderAnimation,
              onChanged:    (v) => n.updateFlags(flags.copyWith(enableCardBorderAnimation: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Attention button animation',
              manifestPath: 'flags.enableAttentionButton',
              description:  'Periodic gradient arc on primary hero CTA',
              value:        flags.enableAttentionButton,
              onChanged:    (v) => n.updateFlags(flags.copyWith(enableAttentionButton: v)),
            ),
          ]),
        ),

        // ── Hero animation per page ────────────────────────────────────────
        AdminSectionCard(
          title: 'Page Hero Animation',
          icon:  Icons.text_fields_rounded,
          subtitle: '· flags.showHeroAnimation*',
          initiallyExpanded: false,
          child: Column(children: [
            Text(
              'Controls whether the typing headline animation fires on each '
              'marketing sub-page. When off, the first phrase renders as a '
              'static gradient-masked heading.',
              style: AppTypography.caption.copyWith(fontSize: 11, height: 1.5),
            ),
            SizedBox(height: AppSpacing.md),
            AdminToggle(
              label:        'Landing page hero',
              manifestPath: 'flags.showHeroAnimationOnPageHero',
              value:        flags.showHeroAnimationOnPageHero,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showHeroAnimationOnPageHero: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'About page hero',
              manifestPath: 'flags.showHeroAnimationOnAbout',
              value:        flags.showHeroAnimationOnAbout,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showHeroAnimationOnAbout: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Features page hero',
              manifestPath: 'flags.showHeroAnimationOnFeatures',
              value:        flags.showHeroAnimationOnFeatures,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showHeroAnimationOnFeatures: v)),
            ),
            AdminDivider(),
            AdminToggle(
              label:        'Pricing page hero',
              manifestPath: 'flags.showHeroAnimationOnPricing',
              value:        flags.showHeroAnimationOnPricing,
              onChanged:    (v) => n.updateFlags(flags.copyWith(showHeroAnimationOnPricing: v)),
            ),
          ]),
        ),
      ]),
    );
  }
}