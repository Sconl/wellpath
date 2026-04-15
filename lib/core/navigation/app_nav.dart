// lib/core/navigation/app_nav.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Reusable navigation shell with three modes.
//   v3.2.0 — [NavItem] + nav lists moved to nav_items.dart (single source of
//            truth). Import updated; all other logic unchanged.
//
//   ┌─ Platform + width resolution ──────────────────────────────────────────┐
//   │  Native Android / iOS    → NavMode.bottom  (always, any screen size)   │
//   │  Web / Desktop ≥1100px   → NavMode.sidebar (collapsible, animated)     │
//   │  Web / Desktop < 1100px  → NavMode.drawer  (hamburger → drawer)        │
//   └────────────────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../style/app_theme.dart';
import '../style/app_branding.dart';

// ← single source of truth for NavItem, kUserNavItems, kTrainerNavItems
import 'nav_items.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kSidebarBreak     = 1100.0;
const double _kSidebarExpanded  = 232.0;
const double _kSidebarCollapsed = 72.0;
const Duration _kSidebarAnim    = Duration(milliseconds: 240);
const double _kNavItemH         = 48.0;
const double _kNavItemRadius    = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// NavMode
// ─────────────────────────────────────────────────────────────────────────────

enum NavMode { sidebar, drawer, bottom }

NavMode _resolveNavMode(BuildContext context) {
  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return NavMode.bottom;
    }
  }
  final w = MediaQuery.of(context).size.width;
  return w >= _kSidebarBreak ? NavMode.sidebar : NavMode.drawer;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNavScope
// ─────────────────────────────────────────────────────────────────────────────

class AppNavScope extends InheritedWidget {
  final NavMode navMode;
  final VoidCallback openDrawer;
  final bool sidebarExpanded;
  final VoidCallback toggleSidebar;

  const AppNavScope({
    super.key,
    required this.navMode,
    required this.openDrawer,
    required this.sidebarExpanded,
    required this.toggleSidebar,
    required super.child,
  });

  static AppNavScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppNavScope>();
    assert(scope != null, 'No AppNavScope found — wrap your screen with AppNavShell.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppNavScope old) =>
      navMode != old.navMode || sidebarExpanded != old.sidebarExpanded;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppNavShell
// ─────────────────────────────────────────────────────────────────────────────

class AppNavShell extends StatefulWidget {
  final String currentRoute;
  final bool isTrainerView;
  final Widget child;
  final String displayName;
  final String? photoUrl;

  const AppNavShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.isTrainerView = false,
    this.displayName   = '',
    this.photoUrl,
  });

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarExpanded = true;

  List<NavItem> get _items =>
      widget.isTrainerView ? kTrainerNavItems : kUserNavItems;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _navigate(BuildContext ctx, String route) {
    if (route != widget.currentRoute) ctx.go(route);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(ctx).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _resolveNavMode(context);
    return AppNavScope(
      navMode:         mode,
      openDrawer:      _openDrawer,
      sidebarExpanded: _sidebarExpanded,
      toggleSidebar: () =>
          setState(() => _sidebarExpanded = !_sidebarExpanded),
      child: _buildScaffold(context, mode),
    );
  }

  Widget _buildScaffold(BuildContext context, NavMode mode) {
    switch (mode) {
      case NavMode.sidebar:
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          body: Row(children: [
            _SidebarNav(
              items:       _items,
              currentRoute: widget.currentRoute,
              expanded:    _sidebarExpanded,
              displayName: widget.displayName,
              photoUrl:    widget.photoUrl,
              onToggle: () =>
                  setState(() => _sidebarExpanded = !_sidebarExpanded),
              onTap: (r) => _navigate(context, r),
            ),
            Expanded(child: widget.child),
          ]),
        );

      case NavMode.drawer:
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: Drawer(
            backgroundColor: AppColors.surface,
            width: _kSidebarExpanded,
            child: _DrawerContent(
              items:        _items,
              currentRoute: widget.currentRoute,
              displayName:  widget.displayName,
              photoUrl:     widget.photoUrl,
              onTap:        (r) => _navigate(context, r),
            ),
          ),
          body: widget.child,
        );

      case NavMode.bottom:
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          body: widget.child,
          bottomNavigationBar: _BottomNavBar(
            items:        _items,
            currentRoute: widget.currentRoute,
            onTap:        (r) => _navigate(context, r),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SidebarNav
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNav extends StatelessWidget {
  final List<NavItem> items;
  final String currentRoute;
  final bool expanded;
  final String displayName;
  final String? photoUrl;
  final VoidCallback onToggle;
  final void Function(String route) onTap;

  const _SidebarNav({
    required this.items,
    required this.currentRoute,
    required this.expanded,
    required this.displayName,
    required this.onToggle,
    required this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _kSidebarAnim,
      curve: Curves.easeInOutCubic,
      width: expanded ? _kSidebarExpanded : _kSidebarCollapsed,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 8, 20),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (expanded) BrandLogo(fallbackSize: LogoSize.sm)
                  else _LogoMark(),
                  if (expanded)
                    _CollapseButton(onToggle: onToggle, expanded: expanded),
                ],
              ),
            ),
            if (!expanded) ...[
              Center(
                child: _CollapseButton(onToggle: onToggle, expanded: expanded)),
              const SizedBox(height: 8),
            ],
            const _SidebarDivider(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: items.map((item) => _SidebarItem(
                  item:     item,
                  active:   item.route == currentRoute,
                  expanded: expanded,
                  onTap:    () => onTap(item.route),
                )).toList(),
              ),
            ),
            const _SidebarDivider(),
            _SidebarUserTile(
                displayName: displayName, photoUrl: photoUrl, expanded: expanded),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        gradient:     AppGradients.button,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(BrandCopy.wordBold[0],
            style: AppTypography.h4.copyWith(color: AppColors.onPrimary)),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final VoidCallback onToggle;
  final bool expanded;
  const _CollapseButton({required this.onToggle, required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded ? 'Collapse sidebar' : 'Expand sidebar',
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: AppColors.border),
          ),
          child: Icon(
            expanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 18, color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavItem item;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.item, required this.active,
    required this.expanded, required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final bg = active
        ? AppColors.primary.withValues(alpha: 0.15)
        : _hovered
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.transparent;
    final iconC = active ? AppColors.primary : AppColors.textMuted;
    final textC = active ? AppColors.primary : AppColors.textSecondary;

    final tile = MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height:  _kNavItemH,
          padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 12 : 0),
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: BorderRadius.circular(_kNavItemRadius),
            border:       active
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.25))
                : null,
          ),
          child: widget.expanded
              ? Row(children: [
                  Icon(active ? widget.item.activeIcon : widget.item.icon,
                      color: iconC, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.item.label,
                        style: AppTypography.h5.copyWith(
                          color:      textC,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                  if (active)
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    ),
                ])
              : Center(
                  child: Icon(
                    active ? widget.item.activeIcon : widget.item.icon,
                    color: iconC, size: 22,
                  ),
                ),
        ),
      ),
    );

    return widget.expanded
        ? tile
        : Tooltip(message: widget.item.label, preferBelow: false, child: tile);
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: AppColors.border);
}

class _SidebarUserTile extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final bool expanded;
  const _SidebarUserTile({
    required this.displayName, required this.expanded, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initial =
        displayName.isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';
    final avatar = Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:  AppColors.primary.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(initial,
                    style: AppTypography.h5.copyWith(color: AppColors.primary)))))
          : Center(
              child: Text(initial,
                  style: AppTypography.h5.copyWith(color: AppColors.primary))),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: expanded ? 16 : 0, vertical: 8),
      child: expanded
          ? Row(children: [
              avatar,
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.trim().split(' ').first,
                    style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text('Member', style: AppTypography.caption),
                ],
              )),
            ])
          : Center(child: avatar),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DrawerContent
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerContent extends StatelessWidget {
  final List<NavItem> items;
  final String currentRoute;
  final String displayName;
  final String? photoUrl;
  final void Function(String route) onTap;
  const _DrawerContent({
    required this.items, required this.currentRoute,
    required this.displayName, required this.onTap, this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(children: [
            BrandLogo(fallbackSize: LogoSize.sm),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: AppColors.textMuted, size: 20),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: items.map((item) => _DrawerItem(
              item:   item,
              active: item.route == currentRoute,
              onTap:  () => onTap(item.route),
            )).toList(),
          ),
        ),
        Divider(color: AppColors.border, height: 1),
        _SidebarUserTile(displayName: displayName, photoUrl: photoUrl, expanded: true),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _DrawerItem({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg    = active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent;
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _kNavItemH,
        margin:  const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(_kNavItemRadius),
          border:       active
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(children: [
          Icon(active ? item.activeIcon : item.icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(item.label,
              style: AppTypography.h5.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
          if (active) ...[
            const Spacer(),
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomNavBar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final List<NavItem> items;
  final String currentRoute;
  final void Function(String route) onTap;
  const _BottomNavBar({
    required this.items, required this.currentRoute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final active = item.route == currentRoute;
            final color  = active ? AppColors.primary : AppColors.textMuted;
            return GestureDetector(
              onTap: () => onTap(item.route),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: Icon(
                      active ? item.activeIcon : item.icon,
                      key:   ValueKey('$active-${item.route}'),
                      color: color, size: 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(item.label,
                      style: AppTypography.caption.copyWith(
                        color:      color,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        fontSize:   10,
                      )),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HamburgerButton — for page headers when NavMode == drawer
// ─────────────────────────────────────────────────────────────────────────────

class HamburgerButton extends StatelessWidget {
  const HamburgerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppNavScope.of(context);
    if (scope.navMode != NavMode.drawer) return const SizedBox.shrink();
    return GestureDetector(
      onTap: scope.openDrawer,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AppColors.border),
        ),
        child: Icon(Icons.menu_rounded,
            size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}