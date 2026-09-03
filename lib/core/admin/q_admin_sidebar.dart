// lib/interface/admin/q_admin_sidebar.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
//   v1.0.0 — Initial. Overview / Content / Brand / Features / Preview nav.
//   v1.1.0 — Added Trainers nav item at position 4 (before Preview).
//             Route: /admin/trainers → ScreenAdminTrainers.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/style/app_theme.dart';

const double _kSidebarW   = 220.0;
const double _kCollapsedW = 56.0;

class _AdminNavItem {
  final String  label;
  final IconData icon;
  final String  route;
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const _kAdminNav = [
  _AdminNavItem(
    label: 'Overview',
    icon:  Icons.dashboard_outlined,
    route: '/admin',
  ),
  _AdminNavItem(
    label: 'Content',
    icon:  Icons.edit_outlined,
    route: '/admin/content',
  ),
  _AdminNavItem(
    label: 'Brand',
    icon:  Icons.palette_outlined,
    route: '/admin/brand',
  ),
  _AdminNavItem(
    label: 'Features',
    icon:  Icons.toggle_on_outlined,
    route: '/admin/features',
  ),
  // ── Added v1.1.0 ─────────────────────────────────────────────────────────
  _AdminNavItem(
    label: 'Trainers',
    icon:  Icons.fitness_center_outlined,
    route: '/admin/trainers',
  ),
  // ─────────────────────────────────────────────────────────────────────────
  _AdminNavItem(
    label: 'Preview',
    icon:  Icons.visibility_outlined,
    route: '/admin/preview',
  ),
];

class QAdminSidebar extends StatelessWidget {
  final bool         expanded;
  final VoidCallback onToggle;
  const QAdminSidebar({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.toString();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve:    Curves.easeInOut,
      width:    expanded ? _kSidebarW : _kCollapsedW,
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(children: [

        // ── Collapse / expand toggle ───────────────────────────────────
        Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Align(
            alignment:
                expanded ? Alignment.centerRight : Alignment.center,
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color:        AppColors.surfaceMid,
                  borderRadius: BorderRadius.circular(7),
                  border:       Border.all(color: AppColors.border),
                ),
                child: Icon(
                  expanded
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),

        // ── Nav items ──────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            children: _kAdminNav.map((item) {
              // Exact match for root /admin, prefix match for all others.
              final active = current.startsWith(item.route) &&
                  (item.route == '/admin'
                      ? current == '/admin'
                      : true);
              return _SidebarItem(
                  item: item, active: active, expanded: expanded);
            }).toList(),
          ),
        ),

        // ── Back to live site ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: GestureDetector(
            onTap: () => context.go('/landing'),
            child: Container(
              height: 36,
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color:        AppColors.tint10(AppColors.secondary),
                borderRadius: AppRadius.cardBR,
                border: Border.all(
                    color: AppColors.tint20(AppColors.secondary)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 14, color: AppColors.secondary),
                  if (expanded) ...[
                    SizedBox(width: 6),
                    Text('Live site',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.secondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SidebarItem
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  final _AdminNavItem item;
  final bool          active;
  final bool          expanded;
  const _SidebarItem({
    required this.item,
    required this.active,
    required this.expanded,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? AppColors.primary.withValues(alpha: 0.14)
        : _hovered
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.transparent;
    final color = widget.active
        ? AppColors.primary
        : AppColors.textSecondary;

    final tile = MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.item.route),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height:   40,
          padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? AppSpacing.sm : 0),
          margin:  EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: AppRadius.cardBR,
            border: widget.active
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22))
                : null,
          ),
          child: widget.expanded
              ? Row(children: [
                  Icon(widget.item.icon, size: 18, color: color),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.item.label,
                    style: AppTypography.h5.copyWith(
                      color:      color,
                      fontWeight: widget.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ])
              : Center(
                  child: Icon(widget.item.icon,
                      size: 20, color: color)),
        ),
      ),
    );

    return widget.expanded
        ? tile
        : Tooltip(
            message:    widget.item.label,
            preferBelow: false,
            child:       tile,
          );
  }
}