// lib/spaces/space_admin/screens/screen_admin_overview.dart
//
// QP CANON: space_admin › screen_admin_overview
// Shows tenant status, publish state, validation, and recent edit summary.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/admin/admin_state.dart';
import '../../../core/admin/admin_schema.dart';

class ScreenAdminOverview extends ConsumerWidget {
  const ScreenAdminOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft   = ref.watch(adminDraftProvider);
    final flags   = draft.flags;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Page header ────────────────────────────────────────────────────
        Text('Overview', style: AppTypography.h2.copyWith(fontSize: 22)),
        SizedBox(height: AppSpacing.xs),
        Text('WellPath · space_site · screen_home',
            style: AppTypography.caption.copyWith(fontSize: 11)),

        SizedBox(height: AppSpacing.xl),

        // ── Status cards ───────────────────────────────────────────────────
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 700 ? 3 : 1;
          return _StatRow(cols: cols, items: [
            _StatCard(
              label: 'Publish State',
              value: _publishLabel(draft.publishState),
              color: _publishColor(draft.publishState),
              icon:  Icons.cloud_upload_outlined,
            ),
            _StatCard(
              label: 'Sections Active',
              value: _countActive(flags).toString(),
              color: AppColors.primary,
              icon:  Icons.layers_outlined,
            ),
            _StatCard(
              label: 'Last Modified',
              value: _relativeTime(draft.lastModified),
              color: AppColors.secondary,
              icon:  Icons.access_time_rounded,
            ),
          ]);
        }),

        SizedBox(height: AppSpacing.xl),

        // ── Quick edit shortcuts ───────────────────────────────────────────
        Text('QUICK EDIT', style: AppTypography.overline),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing:    AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _QuickChip(label: 'Hero copy',       onTap: () => context.go('/admin/content')),
            _QuickChip(label: 'Stats',           onTap: () => context.go('/admin/content')),
            _QuickChip(label: 'Testimonials',    onTap: () => context.go('/admin/content')),
            _QuickChip(label: 'Brand colors',    onTap: () => context.go('/admin/brand')),
            _QuickChip(label: 'Feature flags',   onTap: () => context.go('/admin/features')),
            _QuickChip(label: 'Live preview',    onTap: () => context.go('/admin/preview')),
          ],
        ),

        SizedBox(height: AppSpacing.xl),

        // ── Section visibility summary ─────────────────────────────────────
        Text('SECTION VISIBILITY', style: AppTypography.overline),
        SizedBox(height: AppSpacing.sm),
        _SectionVisibilityTable(flags: flags),

        SizedBox(height: AppSpacing.xl),

        // ── Recent changes ─────────────────────────────────────────────────
        Text('DRAFT INFO', style: AppTypography.overline),
        SizedBox(height: AppSpacing.sm),
        Container(
          padding:     EdgeInsets.all(AppSpacing.md),
          decoration:  BoxDecoration(
            color:        AppColors.surface,
            borderRadius: AppRadius.cardBR,
            border:       Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _InfoRow(label: 'Modified by', value: draft.lastModifiedBy),
            _InfoRow(label: 'Modified at', value: draft.lastModified.toIso8601String()),
            _InfoRow(label: 'State',       value: _publishLabel(draft.publishState)),
            _InfoRow(label: 'Hero badge',  value: draft.hero.badge),
            _InfoRow(label: 'Nav CTA',     value: draft.nav.ctaLabel),
          ]),
        ),
      ]),
    );
  }

  String _publishLabel(AdminPublishState s) => switch (s) {
    AdminPublishState.draft      => 'Draft',
    AdminPublishState.publishing => 'Publishing…',
    AdminPublishState.published  => 'Published',
    AdminPublishState.error      => 'Error',
  };

  Color _publishColor(AdminPublishState s) => switch (s) {
    AdminPublishState.draft      => AppColors.warning,
    AdminPublishState.publishing => AppColors.info,
    AdminPublishState.published  => AppColors.success,
    AdminPublishState.error      => AppColors.error,
  };

  int _countActive(AdminFeatureFlags f) {
    var n = 0;
    if (f.showTrustedStrip)  n++;
    if (f.showStats)         n++;
    if (f.showSteps)         n++;
    if (f.showFeatureCards)  n++;
    if (f.showTestimonials)  n++;
    if (f.showCtaBanner)     n++;
    return n;
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final int cols;
  final List<Widget> items;
  const _StatRow({required this.cols, required this.items});

  @override
  Widget build(BuildContext context) {
    if (cols == 1) {
      return Column(children: items.map((w) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm), child: w)).toList());
    }
    return Row(
      children: items.asMap().entries.map((e) => Expanded(child: Padding(
        padding: EdgeInsets.only(right: e.key < items.length - 1 ? AppSpacing.sm : 0),
        child: e.value,
      ))).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final IconData icon;
  const _StatCard({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        color.withAlpha(20),
            borderRadius: AppRadius.cardBR,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(width: AppSpacing.sm),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTypography.h4.copyWith(color: color, fontSize: 18)),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _QuickChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding:  EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
          decoration: BoxDecoration(
            color:        _h ? AppColors.tint10(AppColors.primary) : AppColors.surface,
            borderRadius: AppRadius.pillBR,
            border:       Border.all(color: _h ? AppColors.primary : AppColors.borderStrong),
          ),
          child: Text(widget.label, style: AppTypography.caption.copyWith(
            color:      _h ? AppColors.primary : AppColors.textSecondary,
            fontSize:   11,
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}

class _SectionVisibilityTable extends StatelessWidget {
  final AdminFeatureFlags flags;
  const _SectionVisibilityTable({required this.flags});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Trusted strip',  flags.showTrustedStrip),
      ('Stats',          flags.showStats),
      ('Steps',          flags.showSteps),
      ('Features',       flags.showFeatureCards),
      ('Testimonials',   flags.showTestimonials),
      ('CTA banner',     flags.showCtaBanner),
      ('Feedback FAB',   flags.showFab),
    ];
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(children: rows.asMap().entries.map((e) {
        final isLast = e.key == rows.length - 1;
        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(e.value.$1, style: AppTypography.body.copyWith(fontSize: 13)),
            const Spacer(),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: e.value.$2 ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(e.value.$2 ? 'On' : 'Off',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: e.value.$2 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                )),
          ]),
        );
      }).toList()),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100,
          child: Text(label, style: AppTypography.caption.copyWith(fontSize: 11))),
        Expanded(child: Text(value,
            style: AppTypography.body.copyWith(fontSize: 12),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}