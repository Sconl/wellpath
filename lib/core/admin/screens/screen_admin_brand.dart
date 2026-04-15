// lib/spaces/space_admin/screens/screen_admin_brand.dart
//
// QP CANON: space_admin › screen_admin_brand
// Edits brand color seeds and identity copy.
// Brand changes are draft-only; colors apply through the merge engine at publish.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/admin/admin_state.dart';
import '../../../core/admin/admin_schema.dart';
import '../../../core/admin/q_admin_form.dart';

class ScreenAdminBrand extends ConsumerWidget {
  const ScreenAdminBrand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(adminDraftProvider);
    final brand = draft.brand;
    final n     = ref.read(adminDraftProvider.notifier);

    void update(AdminBrandConfig b) => n.updateBrand(b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('Brand', style: AppTypography.h2.copyWith(fontSize: 22)),
        SizedBox(height: AppSpacing.xs),
        Text('Color seeds and identity copy · path: space_site.brand',
            style: AppTypography.caption.copyWith(fontSize: 11)),
        SizedBox(height: AppSpacing.xl),

        // ── Color seeds ────────────────────────────────────────────────────
        AdminSectionCard(
          title: 'Color Seeds',
          icon:  Icons.palette_outlined,
          subtitle: '· brand.colors',
          child: Column(children: [
            Text(
              'These three colors seed the entire design system. '
              'Changing them regenerates all derived colors (surfaces, '
              'gradients, borders, etc.) automatically at publish time.',
              style: AppTypography.caption.copyWith(fontSize: 11, height: 1.5),
            ),
            SizedBox(height: AppSpacing.md),
            AdminColorPicker(
              label:        'Primary',
              manifestPath: 'brand.colors.primary',
              hexValue:     brand.primaryHex,
              onChanged:    (v) => update(brand.copyWith(primaryHex: v)),
            ),
            SizedBox(height: AppSpacing.md),
            AdminColorPicker(
              label:        'Secondary',
              manifestPath: 'brand.colors.secondary',
              hexValue:     brand.secondaryHex,
              onChanged:    (v) => update(brand.copyWith(secondaryHex: v)),
            ),
            SizedBox(height: AppSpacing.md),
            AdminColorPicker(
              label:        'Tertiary (warm accent)',
              manifestPath: 'brand.colors.tertiary',
              hexValue:     brand.tertiaryHex,
              onChanged:    (v) => update(brand.copyWith(tertiaryHex: v)),
            ),
            SizedBox(height: AppSpacing.md),
            // Live swatch preview
            _ColorSwatchPreview(
              primary:   brand.primaryColor,
              secondary: brand.secondaryColor,
              tertiary:  brand.tertiaryColor,
            ),
          ]),
        ),

        // ── Identity copy ──────────────────────────────────────────────────
        AdminSectionCard(
          title: 'Identity',
          icon:  Icons.label_outline,
          subtitle: '· brand.identity',
          initiallyExpanded: false,
          child: Column(children: [
            AdminTextField(
              label:        'App name',
              manifestPath: 'brand.identity.appName',
              initialValue: brand.appName,
              onChanged:    (v) => update(brand.copyWith(appName: v)),
            ),
            SizedBox(height: AppSpacing.sm),
            AdminTextField(
              label:        'Tagline',
              manifestPath: 'brand.identity.tagline',
              initialValue: brand.tagline,
              onChanged:    (v) => update(brand.copyWith(tagline: v)),
            ),
            SizedBox(height: AppSpacing.sm),
            AdminTextField(
              label:        'Domain',
              manifestPath: 'brand.identity.domain',
              initialValue: brand.domain,
              onChanged:    (v) => update(brand.copyWith(domain: v)),
            ),
            SizedBox(height: AppSpacing.sm),
            AdminTextField(
              label:        'Copyright line',
              manifestPath: 'brand.identity.copyright',
              initialValue: brand.copyright,
              onChanged:    (v) => update(brand.copyWith(copyright: v)),
            ),
          ]),
        ),

        // ── Note ──────────────────────────────────────────────────────────
        Container(
          padding:    EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:        AppColors.tint10(AppColors.info),
            borderRadius: AppRadius.cardBR,
            border:       Border.all(color: AppColors.tint20(AppColors.info)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(
              'Brand color changes are stored in the admin draft. '
              'Publish applies them through the merge engine. '
              'Font roles are configured in app_branding.dart and require a '
              'code deploy.',
              style: AppTypography.caption.copyWith(
                  fontSize: 11, height: 1.5, color: AppColors.textSecondary),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColorSwatchPreview
// ─────────────────────────────────────────────────────────────────────────────

class _ColorSwatchPreview extends StatelessWidget {
  final Color primary, secondary, tertiary;
  const _ColorSwatchPreview({required this.primary, required this.secondary, required this.tertiary});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Swatch(color: primary,   label: 'Primary'),
      SizedBox(width: AppSpacing.sm),
      _Swatch(color: secondary, label: 'Secondary'),
      SizedBox(width: AppSpacing.sm),
      _Swatch(color: tertiary,  label: 'Tertiary'),
    ]);
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  const _Swatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Container(
        height: 40,
        decoration: BoxDecoration(
          color:        color,
          borderRadius: AppRadius.inputBR,
          border:       Border.all(color: AppColors.borderStrong),
        ),
      ),
      SizedBox(height: 4),
      Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
    ]));
  }
}