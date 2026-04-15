// lib/spaces/space_site/screen_home/section_context/section_context_steps.dart
//
// QP CANON: SECTION CONTEXT — block context_how_it_works
// Renamed from: widgets/site_how_it_works.dart

import 'package:flutter/material.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../../../core/style/app_motion.dart';
import '../../space_site_config.dart';
import '../../space_site_shared.dart';

const double _kWideBreakpoint = 700.0;

class SectionContextSteps extends StatelessWidget {
  final SiteStepsConfig config;
  const SectionContextSteps({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SiteSectionHeader(
        eyebrow:  config.eyebrow,
        headline: config.heading,
        subline:  config.subheading,
      ),
      SizedBox(height: AppSpacing.xxl),
      LayoutBuilder(builder: (ctx, constraints) {
        final wide = constraints.maxWidth > _kWideBreakpoint;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: config.steps.asMap().entries.map((entry) {
              final isLast = entry.key == config.steps.length - 1;
              return Expanded(child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StepCard(step: entry.value)),
                  if (!isLast)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xl),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 20, color: AppColors.textMuted)),
                ],
              ));
            }).toList(),
          );
        }
        return Column(children: config.steps.map((step) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: _StepCard(step: step),
        )).toList());
      }),
    ]);
  }
}

class _StepCard extends StatefulWidget {
  final SpaceSiteStep step;
  const _StepCard({required this.step});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedGradientBorder(
        isActive:     _hovered,
        borderRadius: AppRadius.cardBR,
        arcFraction:  0.25,
        loopDuration: const Duration(milliseconds: 2600),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color:        _hovered ? AppColors.surfaceMid : AppColors.surface,
            borderRadius: AppRadius.cardBR,
            boxShadow: _hovered ? [BoxShadow(
                color: AppColors.primary.withAlpha(25), blurRadius: 20)] : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(widget.step.number,
                style: AppTypography.h1.copyWith(
                  fontSize: 48, fontWeight: FontWeight.w900,
                  color: AppColors.primary.withAlpha(30), height: 1)),
              const Spacer(),
              AnimatedContainer(
                duration: AppDurations.fast,
                padding: EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppColors.tint20(AppColors.primary)
                      : AppColors.tint10(AppColors.primary),
                  borderRadius: AppRadius.cardBR,
                ),
                child: Icon(widget.step.icon, size: 22, color: AppColors.primary),
              ),
            ]),
            SizedBox(height: AppSpacing.md),
            Text(widget.step.title, style: AppTypography.h4.copyWith(fontSize: 18)),
            SizedBox(height: AppSpacing.sm),
            Text(widget.step.body, style: AppTypography.bodySmall.copyWith(height: 1.65)),
          ]),
        ),
      ),
    );
  }
}