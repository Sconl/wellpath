// lib/spaces/space_admin/screens/screen_admin_preview.dart
//
// QP CANON: space_admin › screen_admin_preview
// Renders the landing page live from the admin draft.
// Uses the same rendering path as production (effectiveSiteConfigProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/admin/admin_state.dart';

class ScreenAdminPreview extends ConsumerStatefulWidget {
  const ScreenAdminPreview({super.key});

  @override
  ConsumerState<ScreenAdminPreview> createState() => _ScreenAdminPreviewState();
}

class _ScreenAdminPreviewState extends ConsumerState<ScreenAdminPreview> {
  bool _previewWasOn = false;

  @override
  void initState() {
    super.initState();
    // Auto-enable preview mode when this screen mounts
    _previewWasOn = ref.read(isAdminPreviewProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isAdminPreviewProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    // Restore previous preview state when screen unmounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isAdminPreviewProvider.notifier).state = _previewWasOn;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPreview = ref.watch(isAdminPreviewProvider);

    return Column(children: [

      // ── Preview toolbar ────────────────────────────────────────────────
      Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color:  AppColors.surfaceMid,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Icon(Icons.visibility_outlined, size: 14, color: AppColors.primary),
          SizedBox(width: AppSpacing.xs),
          Text('Live draft preview',
              style: AppTypography.h5.copyWith(fontSize: 12)),
          SizedBox(width: AppSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:        AppColors.tint10(isPreview ? AppColors.success : AppColors.warning),
              borderRadius: AppRadius.pillBR,
              border:       Border.all(color: AppColors.tint20(
                  isPreview ? AppColors.success : AppColors.warning)),
            ),
            child: Text(isPreview ? 'Draft active' : 'Showing published',
              style: AppTypography.caption.copyWith(
                color:    isPreview ? AppColors.success : AppColors.warning,
                fontSize: 10)),
          ),
          const Spacer(),
          // Open landing in new tab (web)
          _PreviewChip(
            label: 'Open site →',
            icon:  Icons.open_in_new_rounded,
            onTap: () => context.go('/landing'),
          ),
          SizedBox(width: AppSpacing.sm),
          _PreviewChip(
            label: 'Toggle preview',
            icon:  Icons.sync_alt_rounded,
            onTap: () => ref.read(isAdminPreviewProvider.notifier).state = !isPreview,
          ),
        ]),
      ),

      // ── Preview area ────────────────────────────────────────────────────
      Expanded(
        child: isPreview
            ? _LivePreviewFrame()
            : _DisabledState(),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LivePreviewFrame
// ─────────────────────────────────────────────────────────────────────────────
// Renders the landing page via the router — same render path as production.
// The effectiveSiteConfigProvider (watched in screen_home_main.dart) now
// returns the draft config, so the page renders with admin edits live.

class _LivePreviewFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color:  AppColors.backgroundAlt,
      child:  Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          decoration: BoxDecoration(
            border: Border(
              left:  BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          // The Router will render /landing which watches effectiveSiteConfigProvider
          // and uses the draft when isAdminPreviewProvider is true.
          child: _PreviewInfo(),
        ),
      ),
    );
  }
}

class _PreviewInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.preview_outlined, size: 48, color: AppColors.primary.withAlpha(120)),
        SizedBox(height: AppSpacing.md),
        Text('Preview mode active',
            style: AppTypography.h3.copyWith(fontSize: 20)),
        SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'The landing page now renders from your draft. '
            'Open the live site link above to see it full-screen, '
            'or navigate to /landing in the same browser tab.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(height: 1.65),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        GestureDetector(
          onTap: () => context.go('/landing'),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient:     AppGradients.button,
              borderRadius: AppRadius.pillBR,
              boxShadow:    AppShadows.buttonGlow,
            ),
            child: Text('View landing page →',
                style: AppTypography.button.copyWith(fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}

class _DisabledState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.visibility_off_outlined, size: 36, color: AppColors.textMuted),
      SizedBox(height: AppSpacing.sm),
      Text('Preview is off — showing published config',
          style: AppTypography.bodySmall),
    ]));
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PreviewChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: AppRadius.pillBR,
          border:       Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(
              fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}