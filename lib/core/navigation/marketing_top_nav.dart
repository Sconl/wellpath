// lib/core/navigation/marketing_top_nav.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// MarketingTopNav — Floating Marketing Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────
//
// FIX v3.3  — Overflow resolved.
//   Root cause: the right-zone Row had mainAxisSize.min inside a SizedBox(200px).
//   "Begin Journey →" at 14 px + 20 px h-padding × 2 + 10 px gap + 40 px circle
//   = ~210 px > 200 px → 9.2 px overflow.
//   Fix: kSideZoneWidth 200 → 220, right-zone uses Flexible on the CTA so it
//   can compress, and the Row drops mainAxisSize.min for mainAxisAlignment.end.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../style/app_branding.dart';
import '../style/app_theme.dart';
import '../style/app_decorations.dart';
import 'nav_items.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

/// Total height of the collapsed bar.
const double kMarketingNavBarHeight = 72.0;

/// Fixed height for all interactive elements (logo, CTA, nav text, profile).
const double _kNavElementHeight = 40.0;

/// Each side zone claims this exact width — guarantees center links are
/// mathematically centred in the viewport regardless of content widths.
/// Increased from 200 → 220 to prevent CTA + profile overflow.
const double kSideZoneWidth = 220.0;

/// Breakpoint below which hamburger activates.
const double kMarketingNavMobileBreak = 800.0;

/// Padding from screen edges.
const double _kNavHPad = 32.0;

/// Scroll offset after which frosted glass activates.
const double _kFrostThreshold = 20.0;

/// Gap between nav link items.
const double _kNavItemSpacing = 28.0;

/// Gap between CTA button and profile circle.
const double _kCtaProfileGap = 10.0;

/// Mobile menu item height.
const double _kMobileItemH = 48.0;

/// Mobile CTA button height.
const double _kMobileCtaH = 52.0;

/// Mobile menu vertical padding.
const double _kMobileMenuVPad = 20.0;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// MarketingTopNav
// ─────────────────────────────────────────────────────────────────────────────

class MarketingTopNav extends StatefulWidget {
  final List<MarketingNavItem> navItems;
  final String ctaLabel;
  final VoidCallback onCta;
  final VoidCallback? onProfileTap;
  final IconData profileIcon;
  final String profileTooltip;
  final ScrollController? scrollController;

  const MarketingTopNav({
    super.key,
    this.navItems        = kDefaultMarketingNavItems,
    required this.ctaLabel,
    required this.onCta,
    this.onProfileTap,
    this.profileIcon     = Icons.person_outline,
    this.profileTooltip  = 'Sign in or create an account',
    this.scrollController,
  });

  @override
  State<MarketingTopNav> createState() => _MarketingTopNavState();
}

class _MarketingTopNavState extends State<MarketingTopNav>
    with SingleTickerProviderStateMixin {

  bool _scrolled   = false;
  bool _mobileOpen = false;

  late final AnimationController _menuCtrl;
  late final Animation<double>   _menuFade;

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(vsync: this, duration: AppDurations.normal);
    _menuFade = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOut);
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    final s = (widget.scrollController?.hasClients ?? false) &&
        widget.scrollController!.offset > _kFrostThreshold;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  void _toggleMenu() {
    setState(() => _mobileOpen = !_mobileOpen);
    _mobileOpen ? _menuCtrl.forward() : _menuCtrl.reverse();
  }

  void _closeMenu() {
    if (!_mobileOpen) return;
    setState(() => _mobileOpen = false);
    _menuCtrl.reverse();
  }

  @override
  void didUpdateWidget(MarketingTopNav old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _menuCtrl.dispose();
    super.dispose();
  }

  double get _mobileMenuHeight =>
      widget.navItems.length * _kMobileItemH +
      _kMobileCtaH + _kMobileMenuVPad * 2 + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _scrolled ? 16.0 : 0.0,
              sigmaY: _scrolled ? 16.0 : 0.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _scrolled || _mobileOpen
                    ? AppColors.background.withAlpha(215)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: _scrolled || _mobileOpen
                        ? AppColors.border
                        : Colors.transparent,
                  ),
                ),
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                return constraints.maxWidth < kMarketingNavMobileBreak
                    ? _buildMobile(context)
                    : _buildDesktop(context);
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────
  //
  // Three columns:
  //   [kSideZoneWidth — logo]  [Expanded — nav links]  [kSideZoneWidth — CTA + profile]
  //
  // OVERFLOW FIX:
  //   Right zone uses a Row with mainAxisAlignment.end (not mainAxisSize.min).
  //   The CTA is wrapped in Flexible so it compresses when space is tight.
  //   Profile circle has a guaranteed fixed width slot at the end.

  Widget _buildDesktop(BuildContext context) {
    return SizedBox(
      height: kMarketingNavBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kNavHPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── Left zone: logo ─────────────────────────────────────────────
            SizedBox(
              width:  kSideZoneWidth,
              height: _kNavElementHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/landing'),
                    child: BrandLogo(
                      fallbackSize: LogoSize.lg,
                      height: _kNavElementHeight,
                    ),
                  ),
                ),
              ),
            ),

            // ── Center: nav links ────────────────────────────────────────────
            Expanded(
              child: SizedBox(
                height: _kNavElementHeight,
                child: Center(
                  child: Wrap(
                    alignment:          WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing:            _kNavItemSpacing,
                    children: widget.navItems
                        .map((item) => _NavLink(item: item))
                        .toList(),
                  ),
                ),
              ),
            ),

            // ── Right zone: CTA + optional profile ───────────────────────────
            // Uses mainAxisAlignment.end so the Row fills the zone and pushes
            // content right. Flexible on the CTA allows it to compress rather
            // than overflow. Profile circle has a fixed reserved slot.
            SizedBox(
              width:  kSideZoneWidth,
              height: _kNavElementHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: _kNavElementHeight,
                      child: _CtaButton(
                        label:     widget.ctaLabel,
                        onPressed: widget.onCta,
                      ),
                    ),
                  ),
                  if (widget.onProfileTap != null) ...[
                    const SizedBox(width: _kCtaProfileGap),
                    // Fixed slot — never squeezed
                    SizedBox(
                      width:  _kNavElementHeight,
                      height: _kNavElementHeight,
                      child: Center(
                        child: _ProfileCircle(
                          icon:      widget.profileIcon,
                          tooltip:   widget.profileTooltip,
                          onPressed: widget.onProfileTap!,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: kMarketingNavBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kNavHPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () { _closeMenu(); context.go('/landing'); },
                    child: BrandLogo(
                      fallbackSize: LogoSize.sm,
                      height: _kNavElementHeight - 4,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width:  _kNavElementHeight,
                  height: _kNavElementHeight,
                  child: Center(
                    child: _HamburgerButton(
                      isOpen: _mobileOpen,
                      onTap:  _toggleMenu,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Collapsible menu
        AnimatedContainer(
          duration: AppDurations.normal,
          curve:    Curves.easeOut,
          height:   _mobileOpen ? _mobileMenuHeight : 0,
          child: ClipRect(
            child: FadeTransition(
              opacity: _menuFade,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _kNavHPad, _kMobileMenuVPad, _kNavHPad, _kMobileMenuVPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...widget.navItems.map((item) =>
                        _MobileNavLink(item: item, onTap: _closeMenu)),
                    SizedBox(height: AppSpacing.sm),
                    _CtaButton(
                      label:     widget.ctaLabel,
                      onPressed: () { _closeMenu(); widget.onCta(); },
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _NavLink — desktop link with gradient hover + animated underline
// ─────────────────────────────────────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final MarketingNavItem item;
  const _NavLink({required this.item});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;
  bool _focused = false;

  static const _base = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.0);

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor:  SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.push(widget.item.route),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: active
                  ? ShaderMask(
                      key: const ValueKey('g'),
                      shaderCallback: (b) => AppGradients.button
                          .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                      blendMode: BlendMode.srcIn,
                      child: Text(widget.item.label,
                        style: _base.copyWith(color: Colors.white),
                        semanticsLabel: widget.item.semanticLabel),
                    )
                  : Text(widget.item.label,
                      key: const ValueKey('n'),
                      style: _base.copyWith(color: AppColors.textSecondary),
                      semanticsLabel: widget.item.semanticLabel),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: AppDurations.fast, curve: Curves.easeOut,
              height: 1.5, width: active ? 36 : 0,
              decoration: BoxDecoration(
                gradient:     active ? AppGradients.button : null,
                color:        active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _MobileNavLink
// ─────────────────────────────────────────────────────────────────────────────

class _MobileNavLink extends StatefulWidget {
  final MarketingNavItem item;
  final VoidCallback onTap;
  const _MobileNavLink({required this.item, required this.onTap});

  @override
  State<_MobileNavLink> createState() => _MobileNavLinkState();
}

class _MobileNavLinkState extends State<_MobileNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () { widget.onTap(); context.push(widget.item.route); },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height:   _kMobileItemH,
          padding:  EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color:        _hovered ? AppColors.tint10(AppColors.primary) : Colors.transparent,
            borderRadius: AppRadius.cardBR,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.item.label,
              style: AppTypography.body.copyWith(
                color:      _hovered ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _CtaButton — gradient pill CTA, desktop inline or mobile full-width
// ─────────────────────────────────────────────────────────────────────────────

class _CtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool fullWidth;
  const _CtaButton({required this.label, required this.onPressed, this.fullWidth = false});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _hovered  = false;
  bool _pressed  = false;
  bool _focused  = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor:  SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
        child: GestureDetector(
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) { setState(() => _pressed = false); widget.onPressed(); },
          onTapCancel: ()  => setState(() => _pressed = false),
          child: AnimatedScale(
            duration: AppDurations.fast, curve: Curves.easeOutBack,
            scale: _pressed ? 0.96 : 1.0,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width:    widget.fullWidth ? double.infinity : null,
              height:   widget.fullWidth ? _kMobileCtaH : _kNavElementHeight,
              padding:  widget.fullWidth
                  ? const EdgeInsets.symmetric(horizontal: 24)
                  : EdgeInsets.symmetric(
                      // Slightly tighter padding to help with fixed-width zone
                      horizontal: AppSpacing.md + 4,
                      vertical:   0,
                    ),
              decoration: BoxDecoration(
                gradient:     active ? AppGradients.buttonHover : AppGradients.button,
                borderRadius: AppRadius.pillBR,
                boxShadow:    active ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.button.copyWith(
                    fontSize:      14,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: 0.3,
                    color:         AppColors.onPrimary,
                  ),
                  semanticsLabel: 'Call to action: ${widget.label}',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ProfileCircle
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCircle extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _ProfileCircle({required this.icon, required this.tooltip, required this.onPressed});

  @override
  State<_ProfileCircle> createState() => _ProfileCircleState();
}

class _ProfileCircleState extends State<_ProfileCircle> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    // Slightly smaller than element height for visual breathing room
    const size = _kNavElementHeight - 2.0;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed(); return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Tooltip(
        message:        widget.tooltip,
        preferBelow:    true,
        verticalOffset: size / 2 + 10,
        waitDuration:   const Duration(milliseconds: 800),
        child: MouseRegion(
          cursor:  SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
          child: GestureDetector(
            onTapDown:   (_) => setState(() => _pressed = true),
            onTapUp:     (_) { setState(() => _pressed = false); widget.onPressed(); },
            onTapCancel: ()  => setState(() => _pressed = false),
            child: AnimatedScale(
              duration: AppDurations.fast, curve: Curves.easeOutBack,
              scale: _pressed ? 0.90 : 1.0,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                width:  size, height: size,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  color:  active ? AppColors.tint10(AppColors.primary) : AppColors.surface,
                  border: Border.all(
                    color: active ? AppColors.borderFocused : AppColors.borderStrong,
                    width: active ? 1.5 : 1.0,
                  ),
                  boxShadow: active
                      ? [BoxShadow(
                          color:       AppColors.primary.withValues(alpha: 0.18),
                          blurRadius:  12,
                          spreadRadius: 1)]
                      : [],
                ),
                child: Center(
                  child: Icon(widget.icon, size: 16,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    semanticLabel: widget.tooltip),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _HamburgerButton — animated open/close icon for mobile
// ─────────────────────────────────────────────────────────────────────────────

class _HamburgerButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _HamburgerButton({required this.isOpen, required this.onTap});

  @override
  State<_HamburgerButton> createState() => _HamburgerButtonState();
}

class _HamburgerButtonState extends State<_HamburgerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _rot;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppDurations.normal);
    _rot  = Tween<double>(begin: 0, end: 0.375)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_HamburgerButton old) {
    super.didUpdateWidget(old);
    if (widget.isOpen != old.isOpen) {
      widget.isOpen ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const size = _kNavElementHeight;
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: size, height: size,
          decoration: BoxDecoration(
            color:        _hovered
                ? AppColors.tint10(AppColors.primary)
                : AppColors.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(
              color: _hovered ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: RotationTransition(
              turns: _rot,
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Icon(
                  widget.isOpen ? Icons.close_rounded : Icons.menu_rounded,
                  key:   ValueKey(widget.isOpen),
                  size:  18,
                  color: _hovered ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}