// lib/core/admin/screens/screen_admin_overview.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Stats, quick edit chips, section visibility table,
//            draft info block.
//   v2.0.0 — Complete UX redesign. Pro-grade admin dashboard:
//            • Time-based greeting using admin's Firestore displayName.
//            • Draft status banner: prominent amber strip when in draft state,
//              dismissed automatically once published.
//            • 4 metric cards in a responsive row with icon, value, label.
//            • Quick actions redesigned as full-width action tiles — two
//              categories:
//                – Admin routes (edit/manage): secondary tinted style.
//                – Live site previews (landing, home, trainers…): outlined
//                  with arrow-out icon — admin router bypass means these
//                  routes are fully accessible without any auth interference.
//            • Section visibility redesigned as a compact icon-dot grid.
//            • System info footer cleaned up into a minimal key-value list.
//            • All layout is responsive via LayoutBuilder (single-column
//              on narrow, two-column on wide ≥ 720px).
//            • Import of auth_providers added for adminName (greeting).
// ─────────────────────────────────────────────────────────────────────────────
//
// LIVE PREVIEW ROUTING:
//   The Quick Actions "Preview" tiles use context.go() to navigate to public
//   and user-space routes (/landing, /home, /trainers, etc.).
//   This works because the router (v3.4.2+) no longer redirects admins away
//   from those routes — admin users can browse any page freely for preview.
//   The sidebar's "Back to live site" link works on the same principle.
//
// CODESPACE RULES: File path line 1 ✓ | CHANGELOG ✓ | CONFIG BLOCK ✓ |
//   Comments explain WHY ✓ | Complete file ✓

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_theme.dart';
import '../../../spaces/auth/providers/auth_providers.dart';
import '../admin_state.dart';
import '../admin_schema.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const double kOverviewPadding         = 28.0;
const double kOverviewWideBreakpoint  = 720.0;
const double kOverviewMetricCardGap   = 12.0;
const double kOverviewActionGap       = 8.0;
const double kDraftBannerBgAlpha      = 0.10;
const double kDraftBannerBorderAlpha  = 0.25;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Internal data classes — not exported; overview-only
// ─────────────────────────────────────────────────────────────────────────────

class _ActionSpec {
  final String   label;
  final IconData icon;
  final String   route;
  final bool     isPreview; // true → "live page" style (outlined + arrow-out)

  const _ActionSpec({
    required this.label,
    required this.icon,
    required this.route,
    this.isPreview = false,
  });
}

// Admin-space management actions
const _kAdminActions = [
  _ActionSpec(
    label: 'Edit Content',
    icon:  Icons.edit_note_rounded,
    route: '/admin/content',
  ),
  _ActionSpec(
    label: 'Manage Brand',
    icon:  Icons.palette_outlined,
    route: '/admin/brand',
  ),
  _ActionSpec(
    label: 'Feature Flags',
    icon:  Icons.toggle_on_rounded,
    route: '/admin/features',
  ),
  _ActionSpec(
    label: 'Manage Trainers',
    icon:  Icons.fitness_center_rounded,
    route: '/admin/trainers',
  ),
];

// Live site preview actions — admins can navigate to any page (router v3.4.2+)
const _kPreviewActions = [
  _ActionSpec(
    label:     'Preview Landing Page',
    icon:      Icons.web_rounded,
    route:     '/landing',
    isPreview: true,
  ),
  _ActionSpec(
    label:     'Preview User Home',
    icon:      Icons.home_outlined,
    route:     '/home',
    isPreview: true,
  ),
  _ActionSpec(
    label:     'Preview Trainers',
    icon:      Icons.people_outline_rounded,
    route:     '/trainers',
    isPreview: true,
  ),
  _ActionSpec(
    label:     'Preview Gyms',
    icon:      Icons.location_on_outlined,
    route:     '/gyms',
    isPreview: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ScreenAdminOverview
// ─────────────────────────────────────────────────────────────────────────────

class ScreenAdminOverview extends ConsumerWidget {
  const ScreenAdminOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft     = ref.watch(adminDraftProvider);
    final flags     = draft.flags;
    final isDraft   = draft.publishState == AdminPublishState.draft;

    // Admin name for the greeting — null while Firestore stream is loading.
    final adminName = ref.watch(currentUserModelProvider)?.displayName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kOverviewPadding),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final wide = constraints.maxWidth >= kOverviewWideBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Greeting + metadata row ──────────────────────────────────
              _GreetingHeader(
                adminName:    adminName,
                isDraft:      isDraft,
                publishState: draft.publishState,
                lastModified: draft.lastModified,
              ),
              const SizedBox(height: 24),

              // ── Draft warning banner ─────────────────────────────────────
              // Only shown when in draft state. A persistent, non-dismissible
              // reminder that changes haven't been published. Vanishes
              // automatically once the admin publishes.
              if (isDraft) ...[
                _DraftBanner(lastModifiedBy: draft.lastModifiedBy),
                const SizedBox(height: 20),
              ],

              // ── 4 metric cards ───────────────────────────────────────────
              _MetricRow(draft: draft, flags: flags, wide: wide),
              const SizedBox(height: 28),

              // ── Two-column content area (wide) / stacked (narrow) ────────
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _QuickActionsPanel()),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: _SectionVisibilityPanel(flags: flags)),
                    ],
                  ),
                )
              else ...[
                _QuickActionsPanel(),
                const SizedBox(height: 20),
                _SectionVisibilityPanel(flags: flags),
              ],

              const SizedBox(height: 28),

              // ── Draft metadata footer ────────────────────────────────────
              _DraftInfoFooter(draft: draft),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GreetingHeader
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String?          adminName;
  final bool             isDraft;
  final AdminPublishState publishState;
  final DateTime         lastModified;

  const _GreetingHeader({
    required this.adminName,
    required this.isDraft,
    required this.publishState,
    required this.lastModified,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60)   return 'just now';
    if (d.inMinutes < 60)   return '${d.inMinutes}m ago';
    if (d.inHours   < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final name = (adminName != null && adminName!.isNotEmpty)
        ? adminName!.split(' ').first
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Greeting ────────────────────────────────────────────────────────
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text:  '${_greeting()}${name != null ? ', $name' : ''}',
              style: AppTypography.h2.copyWith(
                fontSize:   26,
                fontWeight: FontWeight.w700,
                color:      AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text:  ' 👋',
              // Emoji rendered in default system emoji font; no style needed.
              style: AppTypography.h2.copyWith(fontSize: 24),
            ),
          ]),
        ),

        const SizedBox(height: 6),

        // ── Metadata row ─────────────────────────────────────────────────
        Row(children: [
          Text(
            'WellPath Admin Portal',
            style: AppTypography.bodySmall.copyWith(
              color:    AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width:  1, height: 12,
            color:  AppColors.border,
          ),
          Text(
            'Last modified ${_relative(lastModified)}',
            style: AppTypography.bodySmall.copyWith(
              color:    AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          _PublishPill(isDraft: isDraft),
        ]),
      ],
    );
  }
}

class _PublishPill extends StatelessWidget {
  final bool isDraft;
  const _PublishPill({required this.isDraft});

  @override
  Widget build(BuildContext context) {
    final color = isDraft ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBR,
        border:       Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isDraft ? 'Draft' : 'Published',
          style: AppTypography.caption.copyWith(
            color:      color,
            fontSize:   10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DraftBanner
// ─────────────────────────────────────────────────────────────────────────────
// A persistent non-dismissible reminder that there are unpublished changes.
// Shown only in draft state; disappears automatically when published.

class _DraftBanner extends StatelessWidget {
  final String lastModifiedBy;
  const _DraftBanner({required this.lastModifiedBy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.warning.withValues(alpha: kDraftBannerBgAlpha),
        borderRadius: AppRadius.cardBR,
        border:       Border.all(
          color: AppColors.warning.withValues(alpha: kDraftBannerBorderAlpha),
        ),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'You have unpublished changes. Hit Publish in the toolbar to make them live.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.warning, fontSize: 12,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetricRow
// ─────────────────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final dynamic draft;
  final AdminFeatureFlags flags;
  final bool wide;

  const _MetricRow({
    required this.draft,
    required this.flags,
    required this.wide,
  });

  int _activeCount(AdminFeatureFlags f) {
    var n = 0;
    if (f.showTrustedStrip) n++;
    if (f.showStats)        n++;
    if (f.showSteps)        n++;
    if (f.showFeatureCards) n++;
    if (f.showTestimonials) n++;
    if (f.showCtaBanner)    n++;
    if (f.showFab)          n++;
    return n;
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = draft.publishState == AdminPublishState.draft;
    final active  = _activeCount(flags);

    final cards = [
      _MetricCard(
        label: 'Status',
        value: isDraft ? 'Draft' : 'Live',
        icon:  isDraft ? Icons.pending_outlined : Icons.cloud_done_outlined,
        color: isDraft ? AppColors.warning      : AppColors.success,
      ),
      _MetricCard(
        label: 'Active Sections',
        value: '$active / 7',
        icon:  Icons.layers_outlined,
        color: AppColors.primary,
      ),
      _MetricCard(
        label: 'Last Edited',
        value: _relative(draft.lastModified),
        icon:  Icons.history_rounded,
        color: AppColors.secondary,
      ),
      _MetricCard(
        label: 'Last Editor',
        value: (draft.lastModifiedBy as String).split(' ').first,
        icon:  Icons.person_outline_rounded,
        color: AppColors.tertiary,
      ),
    ];

    if (wide) {
      return Row(
        children: cards.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: e.key < cards.length - 1
                  ? kOverviewMetricCardGap : 0,
            ),
            child: e.value,
          ),
        )).toList(),
      );
    }
    // Narrow: 2×2 grid
    return Column(children: [
      Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ]),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, size: 16, color: color)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color:      AppColors.textPrimary,
              fontSize:   17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color:    AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickActionsPanel
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(children: [
            Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text('QUICK ACTIONS', style: AppTypography.overline),
          ]),
          const SizedBox(height: 14),

          // ── Admin management actions ───────────────────────────────────
          Text(
            'Manage',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted, fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          ..._kAdminActions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: kOverviewActionGap),
            child:   _ActionTile(spec: a),
          )),

          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // ── Live preview actions ───────────────────────────────────────
          // These navigate to the real live pages.
          // Admins bypass the public-route redirect (router v3.4.2+) so
          // they see the actual page, not a redirect loop.
          Text(
            'Preview Live Pages',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted, fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          ..._kPreviewActions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: kOverviewActionGap),
            child:   _ActionTile(spec: a),
          )),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final _ActionSpec spec;
  const _ActionTile({required this.spec});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isPreview = widget.spec.isPreview;

    // Preview tiles: outlined with secondary-blue accent.
    // Management tiles: tinted with primary-green accent.
    final borderColor = _hovered
        ? (isPreview ? AppColors.secondary : AppColors.primary)
        : AppColors.border;
    final bgColor = _hovered
        ? (isPreview
            ? AppColors.secondary.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.06))
        : Colors.transparent;
    final iconColor = _hovered
        ? (isPreview ? AppColors.secondary : AppColors.primary)
        : AppColors.textMuted;
    final textColor = _hovered
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.spec.route),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:        bgColor,
            borderRadius: AppRadius.cardBR,
            border: Border.all(
              color: borderColor,
              // Preview tiles always show a border (even when idle) to signal
              // they lead outside the admin space.
              width: (isPreview && !_hovered) ? 1 : 1,
            ),
          ),
          child: Row(children: [
            Icon(widget.spec.icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.spec.label,
                style: AppTypography.body.copyWith(
                  color:    textColor,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              isPreview
                  ? Icons.open_in_new_rounded        // ↗ leads to live page
                  : Icons.chevron_right_rounded,     // → stays in admin space
              size:  14,
              color: _hovered ? iconColor : AppColors.textMuted,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionVisibilityPanel
// ─────────────────────────────────────────────────────────────────────────────

class _SectionVisibilityPanel extends StatelessWidget {
  final AdminFeatureFlags flags;
  const _SectionVisibilityPanel({required this.flags});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Trusted Strip',  flags.showTrustedStrip,  Icons.verified_outlined),
      ('Stats',          flags.showStats,          Icons.bar_chart_rounded),
      ('Steps',          flags.showSteps,          Icons.linear_scale_rounded),
      ('Feature Cards',  flags.showFeatureCards,   Icons.view_module_outlined),
      ('Testimonials',   flags.showTestimonials,   Icons.format_quote_rounded),
      ('CTA Banner',     flags.showCtaBanner,      Icons.campaign_outlined),
      ('Feedback FAB',   flags.showFab,            Icons.chat_bubble_outline_rounded),
    ];

    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(children: [
            Icon(Icons.layers_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text('SECTION VISIBILITY', style: AppTypography.overline),
          ]),
          const SizedBox(height: 14),

          // ── Rows ───────────────────────────────────────────────────────
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final label  = e.value.$1;
            final active = e.value.$2;
            final icon   = e.value.$3;
            return Column(children: [
              _VisibilityRow(label: label, icon: icon, active: active),
              if (!isLast) Divider(color: AppColors.border, height: 1, thickness: 1),
            ]);
          }),

          const SizedBox(height: 14),

          // ── Shortcut to flags ──────────────────────────────────────────
          GestureDetector(
            onTap: () => context.go('/admin/features'),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.tune_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'Manage feature flags →',
                style: AppTypography.caption.copyWith(
                  color:      AppColors.primary,
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     active;

  const _VisibilityRow({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Icon(icon,
            size:  14,
            color: active ? AppColors.textSecondary : AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color:    active ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        // Status dot + label
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.success : AppColors.border,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          active ? 'On' : 'Off',
          style: AppTypography.caption.copyWith(
            color:      active ? AppColors.success : AppColors.textMuted,
            fontSize:   10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DraftInfoFooter
// ─────────────────────────────────────────────────────────────────────────────

class _DraftInfoFooter extends StatelessWidget {
  final dynamic draft;
  const _DraftInfoFooter({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text('DRAFT DETAILS', style: AppTypography.overline),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing:    32,
            runSpacing: 8,
            children: [
              _InfoPair(label: 'Modified by', value: draft.lastModifiedBy as String),
              _InfoPair(label: 'Modified at', value: _fmt(draft.lastModified as DateTime)),
              _InfoPair(label: 'Hero badge',  value: draft.hero.badge as String),
              _InfoPair(label: 'Nav CTA',     value: draft.nav.ctaLabel as String),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoPair extends StatelessWidget {
  final String label;
  final String value;
  const _InfoPair({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color:         AppColors.textMuted,
          fontSize:      9,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value.isNotEmpty ? value : '—',
        style: AppTypography.body.copyWith(
          color:    AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
    ]);
  }
}