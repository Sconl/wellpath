// lib/spaces/space_site/screen_home/section_connect/section_connect_footer.dart
//
// QP CANON: screen_home › section_connect — block: connect_footer
//
// CHANGE: Admin portal link added to the footer bottom row.
//         Routes to /admin — guarded by auth in the router.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/style/app_branding.dart';
import '../../../../core/style/app_theme.dart';
import '../../space_site_config.dart';

class SectionConnectFooter extends StatelessWidget {
  final SiteFooterConfig config;
  const SectionConnectFooter({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(height: 1, color: AppColors.border),
      SizedBox(height: AppSpacing.xl),

      // ── Main footer body ───────────────────────────────────────────────
      LayoutBuilder(builder: (_, constraints) {
        final wide = constraints.maxWidth > 600;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand column
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandLogo(
                    shape:   LogoShape.horizontal,
                    variant: LogoVariant.white,
                    height:  28,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(config.tagline,
                      style: AppTypography.bodySmall.copyWith(fontSize: 13)),
                  SizedBox(height: AppSpacing.sm),
                  Text(config.location,
                      style: AppTypography.caption),
                ],
              )),
              // Link columns
              ...config.columns.map((col) => _FooterColumn(column: col)),
            ],
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BrandLogo(
            shape:   LogoShape.horizontal,
            variant: LogoVariant.white,
            height:  28,
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing:    AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            children: [
              for (final col in config.columns)
                for (final link in col.links)
                  _FooterLink(link: link),
            ],
          ),
        ]);
      }),

      SizedBox(height: AppSpacing.xl),
      Container(height: 1, color: AppColors.border),
      SizedBox(height: AppSpacing.md),

      // ── Bottom row: copyright + admin portal link ─────────────────────
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(config.copyright,
              style: AppTypography.caption.copyWith(fontSize: 11)),

          // Admin portal link — subtle, discoverable but not prominent
          _AdminPortalLink(),
        ],
      ),

      SizedBox(height: AppSpacing.lg),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdminPortalLink — routes to /admin
// ─────────────────────────────────────────────────────────────────────────────

class _AdminPortalLink extends StatefulWidget {
  @override
  State<_AdminPortalLink> createState() => _AdminPortalLinkState();
}

class _AdminPortalLinkState extends State<_AdminPortalLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/admin'),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical:   AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: AppRadius.pillBR,
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : AppColors.border,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size:  11,
              color: _hovered ? AppColors.primary : AppColors.textMuted,
            ),
            SizedBox(width: 4),
            Text(
              'Admin',
              style: AppTypography.caption.copyWith(
                fontSize:   10,
                color:      _hovered ? AppColors.primary : AppColors.textMuted,
                fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FooterColumn
// ─────────────────────────────────────────────────────────────────────────────

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
          child:   _FooterLink(link: link),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FooterLink
// ─────────────────────────────────────────────────────────────────────────────

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
            color:    _hovered ? AppColors.primary : AppColors.textSecondary,
          ),
          child: Text(widget.link.label),
        ),
      ),
    );
  }
}