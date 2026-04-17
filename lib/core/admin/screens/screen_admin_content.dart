// lib/spaces/space_admin/screens/screen_admin_content.dart
//
// QP CANON: space_admin › screen_admin_content
// Edits all copy and content across every section of screen_home_main.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/admin/admin_state.dart';
import '../../../core/admin/q_admin_form.dart';

class ScreenAdminContent extends ConsumerWidget {
  const ScreenAdminContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('Content', style: AppTypography.h2.copyWith(fontSize: 22)),
        SizedBox(height: AppSpacing.xs),
        Text('Edit all landing page copy · Changes auto-save to draft',
            style: AppTypography.caption.copyWith(fontSize: 11)),
        SizedBox(height: AppSpacing.xl),

        // ── NAV ────────────────────────────────────────────────────────────
        _NavEditor(ref: ref),

        // ── SECTION CORE: HERO ─────────────────────────────────────────────
        _HeroEditor(ref: ref),

        // ── SECTION CORE: TRUST ────────────────────────────────────────────
        _TrustEditor(ref: ref),

        // ── SECTION CONTEXT: STATS ─────────────────────────────────────────
        _StatsEditor(ref: ref),

        // ── SECTION CONTEXT: STEPS ─────────────────────────────────────────
        _StepsEditor(ref: ref),

        // ── SECTION CONTEXT: FEATURES ──────────────────────────────────────
        _FeaturesEditor(ref: ref),

        // ── SECTION CONTEXT: TESTIMONIALS ──────────────────────────────────
        _TestimonialsEditor(ref: ref),

        // ── SECTION CONNECT: CTA ───────────────────────────────────────────
        _CtaEditor(ref: ref),

        // ── SECTION CONNECT: FOOTER ────────────────────────────────────────
        _FooterEditor(ref: ref),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav editor
// ─────────────────────────────────────────────────────────────────────────────

class _NavEditor extends ConsumerWidget {
  const _NavEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title: 'Navigation',
      icon:  Icons.navigation_outlined,
      subtitle: '· space_site.nav',
      child: Column(children: [
        AdminTextField(
          label:        'CTA button label',
          manifestPath: 'space_site.nav.ctaLabel',
          initialValue: draft.nav.ctaLabel,
          onChanged:    n.updateNavCtaLabel,
        ),
        SizedBox(height: AppSpacing.md),
        AdminDivider(label: 'Nav links'),
        SizedBox(height: AppSpacing.sm),
        ...draft.nav.navItems.asMap().entries.map((e) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(children: [
            Expanded(child: AdminTextField(
              label:        'Label',
              initialValue: e.value.label,
              onChanged:    (v) => n.updateNavItem(e.key,
                  e.value.copyWith(label: v)),
            )),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: AdminTextField(
              label:        'Route',
              initialValue: e.value.route,
              onChanged:    (v) => n.updateNavItem(e.key,
                  e.value.copyWith(route: v)),
            )),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero editor
// ─────────────────────────────────────────────────────────────────────────────

class _HeroEditor extends ConsumerWidget {
  const _HeroEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Hero',
      icon:     Icons.auto_awesome_outlined,
      subtitle: '· section_core.hero',
      child: Column(children: [
        AdminTextField(
          label:        'Badge text',
          manifestPath: 'section_core.hero.badge',
          initialValue: draft.hero.badge,
          onChanged:    n.updateHeroBadge,
        ),
        SizedBox(height: AppSpacing.md),
        AdminListEditor(
          label:        'Typing phrases',
          manifestPath: 'section_core.hero.phrases',
          items:        draft.hero.phrases,
          addLabel:     '+ Add phrase',
          onItemChanged: n.updateHeroPhrase,
          onRemove:      n.removeHeroPhrase,
          onAdd:         n.addHeroPhrase,
        ),
        SizedBox(height: AppSpacing.md),
        AdminTextArea(
          label:        'Subline',
          manifestPath: 'section_core.hero.subline',
          initialValue: draft.hero.subline,
          onChanged:    n.updateHeroSubline,
          lines:        3,
        ),
        SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: AdminTextField(
            label:        'Primary CTA',
            manifestPath: 'section_core.hero.primaryCtaLabel',
            initialValue: draft.hero.primaryCtaLabel,
            onChanged:    n.updateHeroPrimaryCtaLabel,
          )),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: AdminTextField(
            label:        'Secondary CTA',
            manifestPath: 'section_core.hero.secondaryCtaLabel',
            initialValue: draft.hero.secondaryCtaLabel,
            onChanged:    n.updateHeroSecondaryCtaLabel,
          )),
        ]),
        SizedBox(height: AppSpacing.md),
        AdminTextField(
          label:        'Microcopy',
          manifestPath: 'section_core.hero.microcopy',
          initialValue: draft.hero.microcopy,
          onChanged:    n.updateHeroMicrocopy,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trust editor
// ─────────────────────────────────────────────────────────────────────────────

class _TrustEditor extends ConsumerWidget {
  const _TrustEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Trusted Strip',
      icon:     Icons.verified_outlined,
      subtitle: '· section_core.trust',
      initiallyExpanded: false,
      child: Column(children: [
        AdminTextField(
          label:        'Strip label',
          manifestPath: 'section_core.trust.label',
          initialValue: draft.trusted.label,
          onChanged:    n.updateTrustedLabel,
        ),
        SizedBox(height: AppSpacing.md),
        AdminListEditor(
          label:         'Logo names',
          manifestPath:  'section_core.trust.logos',
          items:         draft.trusted.logos,
          addLabel:      '+ Add logo name',
          onItemChanged: n.updateTrustedLogo,
          onRemove:      n.removeTrustedLogo,
          onAdd:         n.addTrustedLogo,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats editor
// ─────────────────────────────────────────────────────────────────────────────

class _StatsEditor extends ConsumerWidget {
  const _StatsEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Stats',
      icon:     Icons.bar_chart_rounded,
      subtitle: '· section_context.stats',
      initiallyExpanded: false,
      child: Column(children: [
        _SectionHeader(
          eyebrow:    draft.stats.eyebrow,
          heading:    draft.stats.heading,
          subheading: draft.stats.subheading,
          onEyebrow:    n.updateStatsEyebrow,
          onHeading:    n.updateStatsHeading,
          onSubheading: n.updateStatsSubheading,
          prefix: 'section_context.stats',
        ),
        AdminDivider(label: 'Items'),
        SizedBox(height: AppSpacing.sm),
        ...draft.stats.stats.asMap().entries.map((e) {
          final stat = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stat ${e.key + 1}', style: AppTypography.h5.copyWith(fontSize: 12)),
              SizedBox(height: AppSpacing.xs),
              Row(children: [
                Expanded(child: AdminTextField(
                  label: 'Display',  initialValue: stat.display,
                  onChanged: (v) => n.updateStat(e.key, stat.copyWith(display: v)),
                )),
                SizedBox(width: AppSpacing.xs),
                Expanded(child: AdminTextField(
                  label: 'Suffix',   initialValue: stat.suffix,
                  onChanged: (v) => n.updateStat(e.key, stat.copyWith(suffix: v)),
                )),
              ]),
              SizedBox(height: AppSpacing.xs),
              AdminTextField(
                label: 'Label (two lines, use \\n)',
                initialValue: stat.label,
                onChanged: (v) => n.updateStat(e.key, stat.copyWith(label: v)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps editor
// ─────────────────────────────────────────────────────────────────────────────

class _StepsEditor extends ConsumerWidget {
  const _StepsEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Steps',
      icon:     Icons.linear_scale_rounded,
      subtitle: '· section_context.steps',
      initiallyExpanded: false,
      child: Column(children: [
        _SectionHeader(
          eyebrow:      draft.steps.eyebrow,
          heading:      draft.steps.heading,
          subheading:   draft.steps.subheading,
          onEyebrow:    n.updateStepsEyebrow,
          onHeading:    n.updateStepsHeading,
          onSubheading: n.updateStepsSubheading,
          prefix: 'section_context.steps',
        ),
        AdminDivider(label: 'Steps'),
        SizedBox(height: AppSpacing.sm),
        ...draft.steps.steps.asMap().entries.map((e) {
          final step = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step ${e.key + 1} — ${step.number}',
                  style: AppTypography.h5.copyWith(fontSize: 12)),
              SizedBox(height: AppSpacing.xs),
              Row(children: [
                Expanded(child: AdminTextField(
                  label: 'Number', initialValue: step.number,
                  onChanged: (v) => n.updateStep(e.key, step.copyWith(number: v)),
                )),
                SizedBox(width: AppSpacing.xs),
                Expanded(child: AdminTextField(
                  label: 'Title', initialValue: step.title,
                  onChanged: (v) => n.updateStep(e.key, step.copyWith(title: v)),
                )),
              ]),
              SizedBox(height: AppSpacing.xs),
              AdminTextArea(
                label: 'Body', initialValue: step.body,
                onChanged: (v) => n.updateStep(e.key, step.copyWith(body: v)),
                lines: 3,
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Features editor
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesEditor extends ConsumerWidget {
  const _FeaturesEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Features',
      icon:     Icons.featured_play_list_outlined,
      subtitle: '· section_context.features',
      initiallyExpanded: false,
      child: Column(children: [
        _SectionHeader(
          eyebrow:      draft.features.eyebrow,
          heading:      draft.features.heading,
          subheading:   draft.features.subheading,
          onEyebrow:    n.updateFeaturesEyebrow,
          onHeading:    n.updateFeaturesHeading,
          onSubheading: n.updateFeaturesSubheading,
          prefix: 'section_context.features',
        ),
        AdminDivider(label: 'Feature cards'),
        SizedBox(height: AppSpacing.sm),
        ...draft.features.features.asMap().entries.map((e) {
          final f = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Card ${e.key + 1}', style: AppTypography.h5.copyWith(fontSize: 12)),
              SizedBox(height: AppSpacing.xs),
              AdminTextField(
                label: 'Title', initialValue: f.title,
                onChanged: (v) => n.updateFeatureCard(e.key, f.copyWith(title: v)),
              ),
              SizedBox(height: AppSpacing.xs),
              AdminTextArea(
                label: 'Body', initialValue: f.body,
                onChanged: (v) => n.updateFeatureCard(e.key, f.copyWith(body: v)),
                lines: 3,
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Testimonials editor
// ─────────────────────────────────────────────────────────────────────────────

class _TestimonialsEditor extends ConsumerWidget {
  const _TestimonialsEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Testimonials',
      icon:     Icons.format_quote_outlined,
      subtitle: '· section_context.testimonials',
      initiallyExpanded: false,
      child: Column(children: [
        _SectionHeader(
          eyebrow:      draft.testimonials.eyebrow,
          heading:      draft.testimonials.heading,
          subheading:   draft.testimonials.subheading,
          onEyebrow:    n.updateTestimonialsEyebrow,
          onHeading:    n.updateTestimonialsHeading,
          onSubheading: n.updateTestimonialsSubheading,
          prefix: 'section_context.testimonials',
        ),
        AdminDivider(label: 'Quotes'),
        SizedBox(height: AppSpacing.sm),
        ...draft.testimonials.testimonials.asMap().entries.map((e) {
          final t = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quote ${e.key + 1}', style: AppTypography.h5.copyWith(fontSize: 12)),
              SizedBox(height: AppSpacing.xs),
              AdminTextArea(
                label: 'Quote text', initialValue: t.quote,
                onChanged: (v) => n.updateTestimonial(e.key, t.copyWith(quote: v)),
                lines: 3,
              ),
              SizedBox(height: AppSpacing.xs),
              Row(children: [
                Expanded(child: AdminTextField(
                  label: 'Name', initialValue: t.name,
                  onChanged: (v) => n.updateTestimonial(e.key, t.copyWith(name: v)),
                )),
                SizedBox(width: AppSpacing.xs),
                Expanded(child: AdminTextField(
                  label: 'Initials', initialValue: t.initials,
                  onChanged: (v) => n.updateTestimonial(e.key, t.copyWith(initials: v)),
                )),
              ]),
              SizedBox(height: AppSpacing.xs),
              AdminTextField(
                label: 'Location', initialValue: t.location,
                onChanged: (v) => n.updateTestimonial(e.key, t.copyWith(location: v)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA editor
// ─────────────────────────────────────────────────────────────────────────────

class _CtaEditor extends ConsumerWidget {
  const _CtaEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'CTA Banner',
      icon:     Icons.ads_click_outlined,
      subtitle: '· section_connect.cta',
      initiallyExpanded: false,
      child: Column(children: [
        AdminTextField(
          label: 'Eyebrow', manifestPath: 'section_connect.cta.eyebrow',
          initialValue: draft.cta.eyebrow, onChanged: n.updateCtaEyebrow),
        SizedBox(height: AppSpacing.sm),
        AdminTextField(
          label: 'Heading', manifestPath: 'section_connect.cta.heading',
          initialValue: draft.cta.heading, onChanged: n.updateCtaHeading),
        SizedBox(height: AppSpacing.sm),
        AdminTextArea(
          label: 'Subheading', manifestPath: 'section_connect.cta.subheading',
          initialValue: draft.cta.subheading, onChanged: n.updateCtaSubheading,
          lines: 2),
        SizedBox(height: AppSpacing.sm),
        AdminTextField(
          label: 'Button label', manifestPath: 'section_connect.cta.buttonLabel',
          initialValue: draft.cta.buttonLabel, onChanged: n.updateCtaButtonLabel),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer editor
// ─────────────────────────────────────────────────────────────────────────────

class _FooterEditor extends ConsumerWidget {
  const _FooterEditor({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final n = ref.read(adminDraftProvider.notifier);
    return AdminSectionCard(
      title:    'Footer',
      icon:     Icons.web_asset_outlined,
      subtitle: '· section_connect.footer',
      initiallyExpanded: false,
      child: Column(children: [
        AdminTextField(
          label: 'Tagline', manifestPath: 'section_connect.footer.tagline',
          initialValue: draft.footer.tagline, onChanged: n.updateFooterTagline),
        SizedBox(height: AppSpacing.sm),
        AdminTextField(
          label: 'Location', manifestPath: 'section_connect.footer.location',
          initialValue: draft.footer.location, onChanged: n.updateFooterLocation),
        SizedBox(height: AppSpacing.sm),
        AdminTextField(
          label: 'Copyright', manifestPath: 'section_connect.footer.copyright',
          initialValue: draft.footer.copyright, onChanged: n.updateFooterCopyright),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: _SectionHeader — eyebrow / heading / subheading triple field
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String eyebrow, heading, subheading, prefix;
  final ValueChanged<String> onEyebrow, onHeading, onSubheading;
  const _SectionHeader({
    required this.eyebrow, required this.heading, required this.subheading,
    required this.onEyebrow, required this.onHeading, required this.onSubheading,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AdminTextField(
        label: 'Eyebrow', manifestPath: '$prefix.eyebrow',
        initialValue: eyebrow, onChanged: onEyebrow),
      SizedBox(height: AppSpacing.sm),
      AdminTextField(
        label: 'Heading', manifestPath: '$prefix.heading',
        initialValue: heading, onChanged: onHeading),
      SizedBox(height: AppSpacing.sm),
      AdminTextArea(
        label: 'Subheading', manifestPath: '$prefix.subheading',
        initialValue: subheading, onChanged: onSubheading, lines: 2),
      SizedBox(height: AppSpacing.md),
    ]);
  }
}