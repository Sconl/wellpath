// lib/spaces/space_site/screen_home/section_connect/section_connect_footer.dart
//
// QP CANON: SECTION CONNECT — block connect_footer
// Split from: widgets/site_cta_footer.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/style/app_branding.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/style/app_decorations.dart';
import '../../space_site_config.dart';

class SectionConnectFooter extends StatelessWidget {
  final SiteFooterConfig config;
  const SectionConnectFooter({super.key, required this.config});

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
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BrandLogo(shape: LogoShape.horizontal, variant: LogoVariant.white, height: 28),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xl, runSpacing: AppSpacing.lg,
            children: [
              for (final col in config.columns)
                for (final link in col.links) _FooterLink(link: link),
            ],
          ),
        ]);
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
  final SpaceSiteFooterColumn column;
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
  final SpaceSiteFooterLink link;
  const _FooterLink({required this.link});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
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