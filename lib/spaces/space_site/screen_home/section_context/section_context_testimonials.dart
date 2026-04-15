// lib/spaces/space_site/screen_home/section_context/section_context_testimonials.dart
//
// QP CANON: SECTION CONTEXT — block context_testimonials
// Renamed from: widgets/site_testimonials.dart

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../../../core/style/app_motion.dart';
import '../../space_site_config.dart';
import '../../space_site_shared.dart';

const double _kWideBreakpoint = 700.0;

class SectionContextTestimonials extends StatelessWidget {
  final SiteTestimonialsConfig config;
  const SectionContextTestimonials({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow:  config.eyebrow,
        headline: config.heading,
        subline:  config.subheading,
      ),
      SizedBox(height: AppSpacing.xxl),
      LayoutBuilder(builder: (_, constraints) {
        final wide = constraints.maxWidth > _kWideBreakpoint;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: config.testimonials.asMap().entries.map((entry) {
              final isLast = entry.key == config.testimonials.length - 1;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.md),
                child: _TestimonialCard(testimonial: entry.value),
              ));
            }).toList(),
          );
        }
        return Column(children: config.testimonials.map((t) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _TestimonialCard(testimonial: t),
        )).toList());
      }),
    ]);
  }
}

class _TestimonialCard extends StatefulWidget {
  final SpaceSiteTestimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.testimonial;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedGradientBorder(
        isActive:     _hovered,
        borderRadius: AppRadius.cardBR,
        arcFraction:  0.35,
        loopDuration: const Duration(milliseconds: 3000),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color:        _hovered ? AppColors.surfaceMid : AppColors.surface,
            borderRadius: AppRadius.cardBR,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('"',
              style: AppTypography.h1.copyWith(
                fontSize: 48, height: 0.8,
                color: AppColors.primary.withAlpha(80), fontWeight: FontWeight.w900)),
            SizedBox(height: AppSpacing.sm),
            Text(t.quote, style: AppTypography.body.copyWith(
                height: 1.7, fontStyle: FontStyle.italic)),
            SizedBox(height: AppSpacing.lg),
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text(t.initials,
                    style: AppTypography.badge.copyWith(
                      fontSize: 13, color: AppColors.onPrimary, fontWeight: FontWeight.w700))),
              ),
              SizedBox(width: AppSpacing.sm + 2),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.name, style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                Text(t.location, style: AppTypography.caption.copyWith(fontSize: 11)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}