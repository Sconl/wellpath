// lib/features/site/home/widgets/site_cta_footer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/style/app_branding.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../site_config.dart';
import 'site_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SiteCtaBanner
// ─────────────────────────────────────────────────────────────────────────────

class SiteCtaBanner extends StatelessWidget {
  final SiteCtaConfig config;
  final VoidCallback onTap;

  const SiteCtaBanner({super.key, required this.config, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: AppRadius.cardBR,
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: AppShadows.buttonGlow,
      ),
      child: Column(children: [
        // ── 4-part header adapted for the dark gradient surface ────────────
        Text(
          config.eyebrow.toUpperCase(),
          style: AppTypography.overline.copyWith(
              color: AppColors.primary.withAlpha(180)),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          config.heading,
          textAlign: TextAlign.center,
          style: AppTypography.h2.copyWith(fontSize: 34, height: 1.2),
        ),
        SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            config.subheading,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
                height: 1.6, color: AppColors.textSecondary),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SiteGradientButton(
          label: config.buttonLabel,
          onTap: onTap,
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
          fontSize: 16,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SiteFooter
// ─────────────────────────────────────────────────────────────────────────────

class SiteFooter extends StatelessWidget {
  final SiteFooterConfig config;
  const SiteFooter({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(height: 1, color: AppColors.border),
      SizedBox(height: AppSpacing.xl),
      LayoutBuilder(builder: (_, constraints) {
        final wide = constraints.maxWidth > 600;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandLogo(shape: LogoShape.horizontal,
                      variant: LogoVariant.white, height: 28),
                  SizedBox(height: AppSpacing.sm),
                  Text(config.tagline,
                      style: AppTypography.bodySmall.copyWith(fontSize: 13)),
                  SizedBox(height: AppSpacing.sm),
                  Text(config.location, style: AppTypography.caption),
                ],
              )),
              ...config.columns.map((col) => _FooterColumn(column: col)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandLogo(shape: LogoShape.horizontal,
                variant: LogoVariant.white, height: 28),
            SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xl, runSpacing: AppSpacing.lg,
              children: [
                for (final col in config.columns)
                  for (final link in col.links) _FooterLink(link: link),
              ],
            ),
          ],
        );
      }),
      SizedBox(height: AppSpacing.xl),
      Container(height: 1, color: AppColors.border),
      SizedBox(height: AppSpacing.md),
      Text(config.copyright,
          style: AppTypography.caption.copyWith(fontSize: 11)),
      SizedBox(height: AppSpacing.lg),
    ]);
  }
}

class _FooterColumn extends StatelessWidget {
  final SiteFooterColumn column;
  const _FooterColumn({required this.column});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(column.title, style: AppTypography.overline),
        SizedBox(height: AppSpacing.sm),
        ...column.links.map((link) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: _FooterLink(link: link),
        )),
      ]),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final SiteFooterLink link;
  const _FooterLink({required this.link});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(widget.link.route),
        child: AnimatedDefaultTextStyle(
          duration: AppDurations.fast,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 13,
            color: _hovered ? AppColors.primary : AppColors.textSecondary,
          ),
          child: Text(widget.link.label),
        ),
      ),
    );
  }
}