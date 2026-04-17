// lib/core/admin/q_admin_shell.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. QAdminShell with sidebar + toolbar. Publish / reset /
//            preview wired to adminDraftProvider.
//   v2.0.0 — Admin identity + logout added:
//            • Toolbar now shows the logged-in admin's display name and
//              avatar initials (read from currentUserModelProvider).
//            • Logout icon button added at far right of toolbar.
//              Calls authRepositoryProvider.signOut() → GoRouter redirect
//              fires automatically → user lands on /landing.
//            • _handleLogout extracted as a dedicated async method with
//              a mounted check to guard against navigator-after-dispose.
//            • Import of auth_providers added for the two providers above.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/style/app_theme.dart';
import '../../core/style/app_decorations.dart';
import '../../core/style/app_branding.dart';
import '../../core/admin/admin_state.dart';
import '../../core/admin/admin_schema.dart';
import '../../spaces/auth/providers/auth_providers.dart';
import 'q_admin_sidebar.dart';

class QAdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const QAdminShell({super.key, required this.child});

  @override
  ConsumerState<QAdminShell> createState() => _QAdminShellState();
}

class _QAdminShellState extends ConsumerState<QAdminShell> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final draft     = ref.watch(adminDraftProvider);
    final isPreview = ref.watch(isAdminPreviewProvider);
    final isDraft   = draft.publishState == AdminPublishState.draft;

    // Admin identity — read synchronously from the cached Firestore stream.
    // Returns null during the brief init window; toolbar degrades gracefully.
    final adminUser = ref.watch(currentUserModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [

        // ── Top toolbar ───────────────────────────────────────────────────
        _AdminToolbar(
          isDraft:         isDraft,
          isPreview:       isPreview,
          adminName:       adminUser?.displayName,
          onTogglePreview: () =>
              ref.read(isAdminPreviewProvider.notifier).state = !isPreview,
          onPublish:       () => _handlePublish(context),
          onReset:         () => ref.read(adminDraftProvider.notifier).resetToPublished(),
          onLogout:        () => _handleLogout(context),
        ),

        // ── Main area: sidebar + content ──────────────────────────────────
        Expanded(
          child: Row(children: [
            QAdminSidebar(
              expanded: _sidebarExpanded,
              onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
            Expanded(
              child: Container(
                color: AppColors.backgroundAlt,
                child: widget.child,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Publish ───────────────────────────────────────────────────────────────

  void _handlePublish(BuildContext context) async {
    final notifier = ref.read(adminDraftProvider.notifier);
    notifier.setPublishState(AdminPublishState.publishing);
    // TODO: wire to backend publish endpoint
    await Future.delayed(const Duration(seconds: 1));
    notifier.setPublishState(AdminPublishState.published);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Published successfully',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary)),
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  //
  // Calls signOut() on the AuthRepository. Firebase Auth emits null on its
  // authStateChanges stream → authStateProvider emits null → _RouterNotifier
  // fires notifyListeners() → GoRouter re-evaluates its redirect function →
  // user is sent to /landing. No explicit context.go() needed here.

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      // GoRouter redirect handles navigation — nothing else needed.
    } catch (e) {
      debugPrint('[QAdminShell] logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not sign out. Please try again.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
            backgroundColor: AppColors.error,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdminToolbar
// ─────────────────────────────────────────────────────────────────────────────

class _AdminToolbar extends StatelessWidget {
  final bool         isDraft;
  final bool         isPreview;
  final String?      adminName;   // null during Firestore init — degrades gracefully
  final VoidCallback onTogglePreview;
  final VoidCallback onPublish;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  const _AdminToolbar({
    required this.isDraft,
    required this.isPreview,
    required this.adminName,
    required this.onTogglePreview,
    required this.onPublish,
    required this.onReset,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  52,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [

        // ── Brand + label ─────────────────────────────────────────────────
        BrandLogo(
          shape:   LogoShape.icon,
          variant: LogoVariant.colored,
          width:   26,
        ),
        SizedBox(width: AppSpacing.sm),
        Text('Admin',
            style: AppTypography.h5.copyWith(color: AppColors.textMuted)),

        SizedBox(width: AppSpacing.md),

        // ── Draft / published status pill ─────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 3),
          decoration: BoxDecoration(
            color: isDraft
                ? AppColors.tint10(AppColors.warning)
                : AppColors.tint10(AppColors.success),
            borderRadius: AppRadius.pillBR,
            border: Border.all(
              color: isDraft
                  ? AppColors.tint20(AppColors.warning)
                  : AppColors.tint20(AppColors.success),
            ),
          ),
          child: Text(
            isDraft ? 'Draft' : 'Published',
            style: AppTypography.chip.copyWith(
              color:    isDraft ? AppColors.warning : AppColors.success,
              fontSize: 10,
            ),
          ),
        ),

        const Spacer(),

        // ── Action buttons ────────────────────────────────────────────────
        _ToolbarButton(
          label:  isPreview ? 'Exit Preview' : 'Preview',
          icon:   isPreview
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onTap:  onTogglePreview,
          tinted: isPreview,
        ),
        SizedBox(width: AppSpacing.sm),
        _ToolbarButton(
          label: 'Reset',
          icon:  Icons.refresh_rounded,
          onTap: onReset,
        ),
        SizedBox(width: AppSpacing.sm),

        // Publish CTA — gradient button
        GestureDetector(
          onTap: onPublish,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
            decoration: BoxDecoration(
              gradient:     AppGradients.button,
              borderRadius: AppRadius.pillBR,
              boxShadow:    AppShadows.buttonGlow,
            ),
            child: Text(
              'Publish',
              style: AppTypography.button.copyWith(fontSize: 12),
            ),
          ),
        ),

        SizedBox(width: AppSpacing.md),

        // ── Admin identity: initials avatar + name ────────────────────────
        // Shown when Firestore user data has resolved. The avatar provides a
        // quick visual confirmation of who is currently logged in as admin.
        if (adminName != null && adminName!.isNotEmpty) ...[
          Container(
            width:  28,
            height: 28,
            decoration: BoxDecoration(
              gradient:     AppGradients.avatar,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                _initials(adminName!),
                style: AppTypography.overline.copyWith(
                  color:      AppColors.onPrimary,
                  fontSize:   10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.xs + 2),
          Text(
            adminName!.split(' ').first, // first name only — space efficient
            style: AppTypography.caption.copyWith(
              color:    AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
        ],

        // ── Logout button ─────────────────────────────────────────────────
        // Icon-only to keep toolbar compact; tooltip explains the action.
        Tooltip(
          message:    'Sign out',
          preferBelow: false,
          child: GestureDetector(
            onTap: onLogout,
            child: Container(
              width:  30,
              height: 30,
              decoration: BoxDecoration(
                color:        AppColors.tint10(AppColors.error),
                borderRadius: AppRadius.pillBR,
                border: Border.all(
                    color: AppColors.tint20(AppColors.error)),
              ),
              child: Center(
                child: Icon(
                  Icons.logout_rounded,
                  size:  14,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  /// Returns up to two initials from a display name.
  /// "Sconl Peter" → "SP", "Grace" → "G".
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ToolbarButton
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final VoidCallback onTap;
  final bool      tinted;

  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color: tinted
              ? AppColors.tint10(AppColors.primary)
              : AppColors.surfaceMid,
          borderRadius: AppRadius.pillBR,
          border: Border.all(
            color: tinted ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size:  13,
              color: tinted ? AppColors.primary : AppColors.textSecondary),
          SizedBox(width: 4),
          Text(label,
              style: AppTypography.caption.copyWith(
                color:    tinted ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
              )),
        ]),
      ),
    );
  }
}