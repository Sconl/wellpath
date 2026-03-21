// lib/features/home/home_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Auth verification screen. Showed live Firestore fields to
//            confirm auth pipeline end-to-end.
//   v2.0.0 — Full production replacement. User view and Trainer Dashboard
//            wired to real Firestore streams. Wellness logging, trainer
//            discovery, upcoming bookings — all live. Bottom nav bar added.
//            `isTrainerView` flag retained from v1 — router still sends
//            /home → false and /trainer-dashboard → true.
//   v2.1.0 — Fixed ambiguous_extension_member_access: removed _WellnessTypeLabel
//            extension. Replaced withOpacity() → withValues(alpha:). Added
//            const where prefer_const_constructors flagged it.
//   v2.1.1 — Fixed runtime assertion: _BottomNav Container had both `color`
//            and `decoration` set simultaneously. Flutter asserts color == null
//            when decoration is provided. Moved AppColors.surface into the
//            BoxDecoration — color param removed from Container.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_background.dart';
import './providers/home_providers.dart';
import './widgets/trainer_card.dart';
import './widgets/wellness_summary_card.dart';
import './widgets/quick_log_sheet.dart';
import './widgets/upcoming_booking_card.dart';
import '../wellness/data/wellness_log_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// ── Layout ──
const double _kHorizPadding        = 24.0;
const double _kVertPadding         = 28.0;
const double _kSectionGap          = 28.0;
const double _kCardGap             = 12.0;
const double _kTrainerListHeight   = 230.0;
const double _kTrainerCardSpacing  = 12.0;
const double _kAvatarSize          = 36.0;

// ── Routes ── (match app_router.dart)
const String _kDiscoverRoute     = '/discover';
const String _kWellnessRoute     = '/wellness';
const String _kBookingsRoute     = '/bookings';
const String _kProfileRoute      = '/profile';
const String _kAvailabilityRoute = '/availability';

// ── Bottom nav — user tabs ──
const _kUserNavItems = [
  (icon: Icons.home_rounded,            label: 'Home'),
  (icon: Icons.search_rounded,          label: 'Discover'),
  (icon: Icons.favorite_border_rounded, label: 'Wellness'),
  (icon: Icons.calendar_month_rounded,  label: 'Bookings'),
  (icon: Icons.person_outline_rounded,  label: 'Profile'),
];

// ── Bottom nav — trainer tabs ──
const _kTrainerNavItems = [
  (icon: Icons.dashboard_rounded,       label: 'Dashboard'),
  (icon: Icons.event_available_rounded, label: 'Availability'),
  (icon: Icons.calendar_month_rounded,  label: 'Bookings'),
  (icon: Icons.group_outlined,          label: 'Clients'),
  (icon: Icons.person_outline_rounded,  label: 'Profile'),
];

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  final bool isTrainerView;
  const HomeScreen({super.key, this.isTrainerView = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) return;
    setState(() => _navIndex = index);

    if (widget.isTrainerView) {
      switch (index) {
        case 1: context.go(_kAvailabilityRoute); break;
        case 2: context.go(_kBookingsRoute);     break;
        case 3: context.go('/clients');           break;
        case 4: context.go(_kProfileRoute);      break;
      }
    } else {
      switch (index) {
        case 1: context.go(_kDiscoverRoute);  break;
        case 2: context.go(_kWellnessRoute);  break;
        case 3: context.go(_kBookingsRoute);  break;
        case 4: context.go(_kProfileRoute);   break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(firestoreUserProvider);
    final navItems  = widget.isTrainerView ? _kTrainerNavItems : _kUserNavItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        type:          BackgroundType.meshParticle,
        particleStyle: ParticleStyle.drift,
        gradientStyle: GradientStyle.pulse,
        child: SafeArea(
          child: userAsync.when(
            loading: () => Center(
              // Do NOT add const — AppColors.primary is a computed getter.
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Error loading profile.\n'
                  'Pull to refresh or sign out and back in.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return widget.isTrainerView
                  ? _TrainerDashboard(user: user)
                  : _UserHome(user: user);
            },
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        items:        navItems,
        currentIndex: _navIndex,
        onTap:        _onNavTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UserHome
// ─────────────────────────────────────────────────────────────────────────────

class _UserHome extends ConsumerWidget {
  final UserModel user;
  const _UserHome({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wellnessAsync = ref.watch(todayWellnessLogsProvider);
    final trainersAsync = ref.watch(featuredTrainersProvider);
    final bookingsAsync = ref.watch(upcomingBookingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: _kHorizPadding,
        vertical:   _kVertPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _Header(user: user),

          const SizedBox(height: _kSectionGap),

          wellnessAsync.when(
            loading: () => const _SectionShimmer(height: 120),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (logs)  => WellnessSummaryCard(logs: logs),
          ),

          const SizedBox(height: _kSectionGap),

          const _SectionTitle(title: 'Quick Log'),
          const SizedBox(height: _kCardGap),
          _QuickLogRow(context: context),

          const SizedBox(height: _kSectionGap),

          _SectionTitle(
            title:       'Find a Trainer',
            actionLabel: 'See all',
            onAction:    () => context.go(_kDiscoverRoute),
          ),
          const SizedBox(height: _kCardGap),

          trainersAsync.when(
            loading: () => const _SectionShimmer(height: _kTrainerListHeight),
            error:   (_, __) => const _ErrorHint(
              message: 'Trainers unavailable. Check your connection.',
            ),
            data: (trainers) => trainers.isEmpty
                ? const _EmptyState(
                    icon:  Icons.person_search_outlined,
                    title: 'No trainers yet',
                    body:  'Trainers will appear here once they join WellPath.',
                  )
                : SizedBox(
                    height: _kTrainerListHeight,
                    child: ListView.separated(
                      scrollDirection:  Axis.horizontal,
                      itemCount:        trainers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _kTrainerCardSpacing),
                      itemBuilder: (_, i) => TrainerCard(
                        trainer: trainers[i],
                        onTap:   () => context.go('/trainer/${trainers[i].id}'),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: _kSectionGap),

          _SectionTitle(
            title:       'Upcoming Sessions',
            actionLabel: 'View all',
            onAction:    () => context.go(_kBookingsRoute),
          ),
          const SizedBox(height: _kCardGap),

          bookingsAsync.when(
            loading: () => const _SectionShimmer(height: 80),
            error:   (_, __) => const _ErrorHint(
              message: 'Bookings unavailable right now.',
            ),
            data: (bookings) => bookings.isEmpty
                ? _EmptyState(
                    icon:     Icons.calendar_today_outlined,
                    title:    'No upcoming sessions',
                    body:     'Book a trainer to get started.',
                    ctaLabel: 'Find a trainer',
                    onCta:    () => context.go(_kDiscoverRoute),
                  )
                : Column(
                    children: [
                      for (final b in bookings) ...[
                        UpcomingBookingCard(
                          booking: b,
                          onTap:   () => context.go('/bookings/${b.id}'),
                        ),
                        const SizedBox(height: _kCardGap),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerDashboard
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerDashboard extends ConsumerWidget {
  final UserModel user;
  const _TrainerDashboard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(trainerBookingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: _kHorizPadding,
        vertical:   _kVertPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _Header(user: user),

          const SizedBox(height: _kSectionGap),

          bookingsAsync.when(
            loading: () => const _SectionShimmer(height: 80),
            error:   (_, __) => const SizedBox.shrink(),
            data: (bookings) => _TrainerStatsRow(bookingCount: bookings.length),
          ),

          const SizedBox(height: _kSectionGap),

          const _SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: _kCardGap),

          Row(
            children: [
              Expanded(
                child: _TrainerActionButton(
                  icon:  Icons.event_available_rounded,
                  label: 'Add Availability',
                  onTap: () => context.go(_kAvailabilityRoute),
                ),
              ),
              const SizedBox(width: _kCardGap),
              Expanded(
                child: _TrainerActionButton(
                  icon:  Icons.calendar_month_rounded,
                  label: 'View Bookings',
                  onTap: () => context.go(_kBookingsRoute),
                ),
              ),
            ],
          ),

          const SizedBox(height: _kSectionGap),

          _SectionTitle(
            title:       'Upcoming Sessions',
            actionLabel: 'View all',
            onAction:    () => context.go(_kBookingsRoute),
          ),
          const SizedBox(height: _kCardGap),

          bookingsAsync.when(
            loading: () => const _SectionShimmer(height: 80),
            error:   (_, __) => const _ErrorHint(
              message: 'Bookings unavailable right now.',
            ),
            data: (bookings) => bookings.isEmpty
                ? _EmptyState(
                    icon:     Icons.calendar_today_outlined,
                    title:    'No upcoming sessions',
                    body:     'Add your availability so clients can book you.',
                    ctaLabel: 'Add availability',
                    onCta:    () => context.go(_kAvailabilityRoute),
                  )
                : Column(
                    children: [
                      for (final b in bookings) ...[
                        UpcomingBookingCard(
                          booking: b,
                          onTap:   () => context.go('/bookings/${b.id}'),
                        ),
                        const SizedBox(height: _kCardGap),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final UserModel user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour      = DateTime.now().hour;
    final timeWord  = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    final firstName = user.displayName.trim().split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:  'Well',
                      style: AppTypography.brandBold.copyWith(
                        fontSize: 22,
                        color:    AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text:  'Path',
                      style: AppTypography.brandLight.copyWith(
                        fontSize: 22,
                        color:    AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Good $timeWord, $firstName 👋',
                style: AppTypography.helper.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () => context.go(_kProfileRoute),
          child: Container(
            width:  _kAvatarSize,
            height: _kAvatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl!,
                      fit:          BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarInitial(displayName: user.displayName),
                    ),
                  )
                : _AvatarInitial(displayName: user.displayName),
          ),
        ),

        const SizedBox(width: 10),

        IconButton(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            // GoRouter authStateProvider redirect handles navigation.
            // No explicit context.go() — see auth docs / Bug 4 notes.
          },
          icon:        const Icon(Icons.logout_outlined, size: 20),
          color:       AppColors.textMuted,
          tooltip:     'Sign out',
          padding:     EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AvatarInitial
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarInitial extends StatelessWidget {
  final String displayName;
  const _AvatarInitial({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return Center(
      child: Text(
        initial,
        style: AppTypography.h5.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionTitle
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String        title;
  final String?       actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline:       TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        ),
        if (actionLabel != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTypography.helper.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickLogRow
// ─────────────────────────────────────────────────────────────────────────────

class _QuickLogRow extends StatelessWidget {
  final BuildContext context;
  const _QuickLogRow({required this.context});

  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        Expanded(
          child: _QuickLogButton(
            icon:    Icons.fitness_center_rounded,
            label:   'Workout',
            color:   AppColors.primary,
            context: context,
            type:    WellnessType.workout,
          ),
        ),
        const SizedBox(width: _kCardGap),
        Expanded(
          child: _QuickLogButton(
            icon:    Icons.water_drop_rounded,
            label:   'Water',
            color:   AppColors.secondary,
            context: context,
            type:    WellnessType.water,
          ),
        ),
        const SizedBox(width: _kCardGap),
        Expanded(
          child: _QuickLogButton(
            icon:    Icons.bedtime_rounded,
            label:   'Sleep',
            color:   AppColors.tertiary,
            context: context,
            type:    WellnessType.sleep,
          ),
        ),
      ],
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final BuildContext context;
  final WellnessType type;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.context,
    required this.type,
  });

  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      onTap: () => _openSheet(context, type),
      child: Container(
        padding:    const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.08),
          borderRadius: AppRadius.cardBR,
          border:       Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.helper.copyWith(
                color:      color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext ctx, WellnessType t) async {
    final saved = await showModalBottomSheet<bool>(
      context:            ctx,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder:            (_) => QuickLogSheet(type: t),
    );

    if (saved == true && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          // Explicit extension override — avoids ambiguity between WellnessTypeX
          // (wellness_log_model.dart) and any extension that might define
          // displayLabel on WellnessType in the future.
          content: Text(
            '${WellnessTypeX(t).displayLabel} logged ✓',
            style: AppTypography.helper.copyWith(color: AppColors.onPrimary),
          ),
          backgroundColor: AppColors.primary,
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerStatsRow
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerStatsRow extends StatelessWidget {
  final int bookingCount;
  const _TrainerStatsRow({required this.bookingCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: bookingCount.toString(),
            label: 'Upcoming\nSessions',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: _kCardGap),
        Expanded(
          child: _StatTile(
            value: '0',
            label: 'Pending\nRequests',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.h2.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.helper.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerActionButton
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _TrainerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:    const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: AppDecorations.card,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        AppColors.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.inputBR,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.helper.copyWith(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData      icon;
  final String        title;
  final String        body;
  final String?       ctaLabel;
  final VoidCallback? onCta;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: AppDecorations.card,
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style:     AppTypography.h5.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style:     AppTypography.helper.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onCta,
              child: Text(
                ctaLabel!,
                style: AppTypography.helper.copyWith(
                  color:      AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionShimmer
// ─────────────────────────────────────────────────────────────────────────────

class _SectionShimmer extends StatelessWidget {
  final double height;
  const _SectionShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  double.infinity,
      height: height,
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color:       AppColors.primary.withValues(alpha: 0.3),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorHint
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorHint extends StatelessWidget {
  final String message;
  const _ErrorHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: AppTypography.helper.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomNav
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final List<({IconData icon, String label})> items;
  final int                currentIndex;
  final ValueChanged<int>  onTap;

  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Container assertion: color and decoration cannot both be set.
    // Color must live inside the BoxDecoration — not as a sibling param.
    return Container(
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top:  false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavItem(
                icon:     items[i].icon,
                label:    items[i].label,
                selected: i == currentIndex,
                onTap:    () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.helper.copyWith(
                color:      color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize:   10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}