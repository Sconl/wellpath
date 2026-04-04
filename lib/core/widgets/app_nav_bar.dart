// lib/core/widgets/app_nav_bar.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial creation — extracted from landing_page.dart.
//   • v2 — nav item label now applies the brand gradient on hover via
//     ShaderMask wrapping the Text widget, cross-faded with AnimatedSwitcher.
//     AnimatedDefaultTextStyle cannot animate to a gradient (it only handles
//     solid colors) — ShaderMask is the correct Flutter approach.
//     The gradient underline and the gradient label animate together, giving
//     a cohesive hover state.
// ─────────────────────────────────────────────────────────────────────────────

// HOW TO USE ON ANY PAGE:
//
//   AppNavBar(
//     navItems: const [
//       AppNavItem(label: 'About',    route: '/about'),
//       AppNavItem(label: 'Features', route: '/features'),
//       AppNavItem(label: 'Pricing',  route: '/pricing'),
//     ],
//     ctaLabel:       'Begin Journey →',
//     onCta:          () => context.push('/login'),
//     onProfileTap:   () => context.push('/profile'),
//   )
//
//   Logo size:
//     LogoSize.lg → landing page / hero (48pt)
//     LogoSize.sm → authenticated inner pages (22pt)
//
//   Profile circle:
//     Omit onProfileTap to hide the circle (e.g., login/signup pages).
//     Pass profileTooltip with the user's name when authenticated.
//     Pass profileIcon: Icons.settings for settings-adjacent pages.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_branding.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

/// Gap between nav items in the center Wrap.
const double _kNavItemSpacing = 28.0;

/// Gap between the CTA button and the profile circle.
const double _kCtaProfileGap = 14.0;

/// CTA button label font size.
const double _kCtaFontSize = 15.0;

/// Diameter of the profile/settings circle.
const double _kProfileSize = 40.0;

/// Icon size inside the profile circle.
const double _kProfileIconSize = 18.0;

/// Default tooltip shown on the profile circle.
const String _kProfileTooltipDefault = 'Profile & Settings';

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// AppNavItem — data class for a single nav link
// ─────────────────────────────────────────────────────────────────────────────

class AppNavItem {
  final String label;
  final String route;
  const AppNavItem({required this.label, required this.route});
}


// ─────────────────────────────────────────────────────────────────────────────
// AppNavBar — the reusable top navigation bar
// ─────────────────────────────────────────────────────────────────────────────
//
// Layout (left → right):
//   [BrandLogo]   [nav items Wrap]   [CTA Button] [ProfileCircle?]
//
// BrandLogo and ProfileCircle are fixed.
// The page owns all business logic — AppNavBar owns only visual state.

class AppNavBar extends StatelessWidget {
  final List<AppNavItem> navItems;
  final String ctaLabel;
  final VoidCallback onCta;
  final VoidCallback? onProfileTap;
  final IconData profileIcon;
  final String profileTooltip;
  final LogoSize logoSize;

  const AppNavBar({
    super.key,
    required this.navItems,
    required this.ctaLabel,
    required this.onCta,
    this.onProfileTap,
    this.profileIcon    = Icons.person_outline,
    this.profileTooltip = _kProfileTooltipDefault,
    this.logoSize       = LogoSize.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // ── Brand logo — always top-left ────────────────────────────────────
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/landing'),
            child: BrandLogo(size: logoSize),
          ),
        ),

        // ── Center nav links ─────────────────────────────────────────────────
        Expanded(
          child: Center(
            child: Wrap(
              alignment:          WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing:            _kNavItemSpacing,
              children:           navItems
                  .map((item) => _NavItem(item: item))
                  .toList(),
            ),
          ),
        ),

        // ── CTA button ───────────────────────────────────────────────────────
        _NavCta(label: ctaLabel, onPressed: onCta),

        // ── Profile circle — rightmost ────────────────────────────────────────
        if (onProfileTap != null) ...[
          const SizedBox(width: _kCtaProfileGap),
          _ProfileCircle(
            icon:      profileIcon,
            tooltip:   profileTooltip,
            onPressed: onProfileTap!,
          ),
        ],

      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _NavItem — a single center nav link
// ─────────────────────────────────────────────────────────────────────────────
//
// Resting:  textSecondary color, no underline
// Hover:    brand gradient text (via ShaderMask) + growing gradient underline
//
// Gradient text implementation:
//   AnimatedDefaultTextStyle cannot express gradient text — it only handles
//   solid Color values. ShaderMask wraps the Text widget and applies a
//   LinearGradient as a paint shader. The text's own color must be white
//   (or any solid color) for the ShaderMask blendMode.srcIn to work correctly:
//   the gradient replaces that solid color, pixel by pixel.
//
//   AnimatedSwitcher cross-fades between the solid-color Text (resting) and
//   the ShaderMask-wrapped Text (hover). The ValueKey on each child tells
//   AnimatedSwitcher they are different widgets and triggers the fade.

class _NavItem extends StatefulWidget {
  final AppNavItem item;
  const _NavItem({required this.item});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  static const TextStyle _baseStyle = TextStyle(
    // Use a concrete fontSize here rather than AppTypography.body() to avoid
    // a GoogleFonts call in the StatelessWidget const context. The font family
    // is set by the MaterialApp textTheme — which already applies BrandCopy.fontFamily.
    fontSize:   14,
    fontWeight: FontWeight.w600,
    height:     1.0,
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(widget.item.route),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Label text — solid or gradient ────────────────────────────
            AnimatedSwitcher(
              duration: AppDurations.fast,
              // FadeTransition gives a clean cross-fade between the two states.
              // The default AnimatedSwitcher transition is also a fade, but
              // explicitly specifying it makes the intent clear.
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _hovered
                  // Hover state: ShaderMask applies the brand gradient to the text.
                  // blendMode.srcIn: the gradient is drawn where the source (text)
                  // pixels exist, using the text's alpha mask as the cutout.
                  // The child Text must use color: Colors.white — this is the
                  // "source" that gets replaced by the gradient shader.
                  ? ShaderMask(
                      key:  const ValueKey('gradient'),
                      shaderCallback: (bounds) =>
                          AppGradients.button.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        widget.item.label,
                        style: _baseStyle.copyWith(color: Colors.white),
                      ),
                    )
                  // Resting state: plain text in textSecondary
                  : Text(
                      key:   const ValueKey('normal'),
                      widget.item.label,
                      style: _baseStyle.copyWith(color: AppColors.textSecondary),
                    ),
            ),

            // ── Underline — grows in on hover ─────────────────────────────
            // width: 0 → 36px animated with the same duration as the label
            // color swap. Both changes land at the same time → cohesive state.
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: AppDurations.fast,
              curve:    Curves.easeOut,
              height:   1.5,
              width:    _hovered ? 36 : 0,
              // ShaderDecoration for the underline to match the text gradient.
              // We use a BoxDecoration with gradient instead of a solid color
              // so the underline matches the text gradient exactly.
              decoration: BoxDecoration(
                gradient:     _hovered ? AppGradients.button : null,
                color:        _hovered ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _NavCta — gradient CTA button with hover animation
// ─────────────────────────────────────────────────────────────────────────────

class _NavCta extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _NavCta({required this.label, required this.onPressed});

  @override
  State<_NavCta> createState() => _NavCtaState();
}

class _NavCtaState extends State<_NavCta> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); widget.onPressed(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: AppDurations.fast,
          curve:    Curves.easeOutBack,
          scale:    _pressed ? 0.96 : 1.0,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl - AppSpacing.md,
              vertical:   AppSpacing.sm + 6,
            ),
            decoration: BoxDecoration(
              gradient:     _hovered ? AppGradients.buttonHover : AppGradients.button,
              borderRadius: AppRadius.pillBR,
              boxShadow:    _hovered ? AppShadows.buttonGlowHover : AppShadows.buttonGlow,
            ),
            child: Text(
              widget.label,
              style: AppTypography.button.copyWith(
                fontSize:      _kCtaFontSize,
                fontWeight:    FontWeight.w800,
                letterSpacing: 0.5,
                color:         AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ProfileCircle — circular profile/settings icon, rightmost in AppNavBar
// ─────────────────────────────────────────────────────────────────────────────
//
// Resting:  surface bg, borderStrong border, textSecondary icon
// Hover:    tint10(primary) bg, primary border + glow, primary icon
//
// Future: when authenticated, wrap in a CircleAvatar with backgroundImage.
// The hover tint and tooltip still apply — size (kProfileSize) stays constant.

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

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:        widget.tooltip,
      preferBelow:    true,
      verticalOffset: _kProfileSize / 2 + 10,
      waitDuration:   const Duration(milliseconds: 800),
      child: MouseRegion(
        cursor:  SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) { setState(() => _pressed = false); widget.onPressed(); },
          onTapCancel: ()  => setState(() => _pressed = false),
          child: AnimatedScale(
            duration: AppDurations.fast,
            curve:    Curves.easeOutBack,
            scale:    _pressed ? 0.90 : 1.0,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve:    Curves.easeOut,
              width:    _kProfileSize,
              height:   _kProfileSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered
                    ? AppColors.tint10(AppColors.primary)
                    : AppColors.surface,
                border: Border.all(
                  color: _hovered ? AppColors.borderFocused : AppColors.borderStrong,
                  width: _hovered ? 1.5 : 1.0,
                ),
                boxShadow: _hovered
                    ? [BoxShadow(
                        color:        AppColors.primary.withValues(alpha: 0.18),
                        blurRadius:   12,
                        spreadRadius: 1,
                      )]
                    : [],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size:  _kProfileIconSize,
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