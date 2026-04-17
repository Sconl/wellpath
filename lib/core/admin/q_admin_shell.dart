// lib/interface/admin/q_admin_shell.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// QAdminShell — Authenticated Admin Wrapper
// ─────────────────────────────────────────────────────────────────────────────
// Wraps all space_admin screens. Provides sidebar navigation and a persistent
// toolbar. Content area renders the selected screen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/style/app_theme.dart';
import '../../core/style/app_decorations.dart';
import '../../core/style/app_branding.dart';
import '../../core/admin/admin_state.dart';
import '../../core/admin/admin_schema.dart';
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
    final draft       = ref.watch(adminDraftProvider);
    final isPreview   = ref.watch(isAdminPreviewProvider);
    final isDraft     = draft.publishState == AdminPublishState.draft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [

        // ── Top toolbar ───────────────────────────────────────────────────
        _AdminToolbar(
          isDraft:   isDraft,
          isPreview: isPreview,
          onTogglePreview: () =>
              ref.read(isAdminPreviewProvider.notifier).state = !isPreview,
          onPublish: () => _handlePublish(context),
          onReset:   () => ref.read(adminDraftProvider.notifier).resetToPublished(),
        ),

        // ── Main area: sidebar + content ──────────────────────────────────
        Expanded(
          child: Row(children: [
            QAdminSidebar(
              expanded:   _sidebarExpanded,
              onToggle:   () => setState(() => _sidebarExpanded = !_sidebarExpanded),
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
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdminToolbar
// ─────────────────────────────────────────────────────────────────────────────

class _AdminToolbar extends StatelessWidget {
  final bool isDraft;
  final bool isPreview;
  final VoidCallback onTogglePreview;
  final VoidCallback onPublish;
  final VoidCallback onReset;

  const _AdminToolbar({
    required this.isDraft, required this.isPreview,
    required this.onTogglePreview, required this.onPublish, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        // Logo mark
        BrandLogo(shape: LogoShape.icon, variant: LogoVariant.colored, width: 28),
        SizedBox(width: AppSpacing.sm),
        Text('Admin', style: AppTypography.h5.copyWith(color: AppColors.textMuted)),

        const Spacer(),

        // Draft status
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
          decoration: BoxDecoration(
            color:        isDraft
                ? AppColors.tint10(AppColors.warning)
                : AppColors.tint10(AppColors.success),
            borderRadius: AppRadius.pillBR,
            border: Border.all(color: isDraft
                ? AppColors.tint20(AppColors.warning)
                : AppColors.tint20(AppColors.success)),
          ),
          child: Text(isDraft ? 'Draft' : 'Published',
            style: AppTypography.chip.copyWith(
              color: isDraft ? AppColors.warning : AppColors.success, fontSize: 10)),
        ),

        SizedBox(width: AppSpacing.md),

        // Preview toggle
        _ToolbarButton(
          label:    isPreview ? 'Exit Preview' : 'Preview',
          icon:     isPreview ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          onTap:    onTogglePreview,
          tinted:   isPreview,
        ),

        SizedBox(width: AppSpacing.sm),

        // Reset
        _ToolbarButton(
          label: 'Reset', icon: Icons.refresh_rounded, onTap: onReset),

        SizedBox(width: AppSpacing.sm),

        // Publish
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
            child: Text('Publish',
              style: AppTypography.button.copyWith(fontSize: 12)),
          ),
        ),
      ]),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool tinted;
  const _ToolbarButton({
    required this.label, required this.icon, required this.onTap, this.tinted = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color:        tinted ? AppColors.tint10(AppColors.primary) : AppColors.surfaceMid,
          borderRadius: AppRadius.pillBR,
          border: Border.all(
            color: tinted ? AppColors.primary : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13,
              color: tinted ? AppColors.primary : AppColors.textSecondary),
          SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(
            color: tinted ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11)),
        ]),
      ),
    );
  }
}