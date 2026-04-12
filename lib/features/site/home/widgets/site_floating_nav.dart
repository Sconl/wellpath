// lib/features/site/home/widgets/site_floating_nav.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Site — SiteFloatingNav
// ─────────────────────────────────────────────────────────────────────────────
// Scroll-aware floating nav bar — transparent at top, frosted on scroll.
// Positioned in a Stack above the page body; never scrolls with content.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/style/app_branding.dart';
import '../../../../core/style/app_theme.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../site_config.dart';

const double kSiteNavBarHeight  = 72.0;
const double _kScrollThreshold  = 20.0;
const double _kNavPaddingH      = 32.0;

class SiteFloatingNav extends StatefulWidget {
  final SiteConfig config;
  final ScrollController scrollController;
  final VoidCallback onCta;
  final VoidCallback? onProfileTap;

  const SiteFloatingNav({
    super.key,
    required this.config,
    required this.scrollController,
    required this.onCta,
    this.onProfileTap,
  });

  @override
  State<SiteFloatingNav> createState() => _SiteFloatingNavState();
}

class _SiteFloatingNavState extends State<SiteFloatingNav> {
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final nowScrolled = widget.scrollController.hasClients &&
        widget.scrollController.offset > _kScrollThreshold;
    if (nowScrolled != _scrolled) setState(() => _scrolled = nowScrolled);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _scrolled ? 14.0 : 0.0,
              sigmaY: _scrolled ? 14.0 : 0.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: kSiteNavBarHeight,
              decoration: BoxDecoration(
                color: _scrolled
                    ? AppColors.background.withAlpha(210)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: _scrolled ? AppColors.border : Colors.transparent,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kNavPaddingH),
                child: AppNavBar(
                  navItems:       widget.config.nav.navItems,
                  logoSize:       LogoSize.lg,
                  ctaLabel:       widget.config.nav.ctaLabel,
                  onCta:          widget.onCta,
                  onProfileTap:   widget.onProfileTap,
                  profileIcon:    widget.config.nav.profileIcon,
                  profileTooltip: widget.config.nav.profileTooltip,
                  fullWidth:      true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}