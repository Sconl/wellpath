// lib/features/profile/presentation/profile_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. User profile + settings screen:
//            - Profile card: avatar, name, email, member since.
//            - Booking summary strip: upcoming / total / cancelled counts.
//            - Notification preferences: 6 toggles backed by SharedPreferences.
//            - Account section: sign out (existing auth provider).
//            - All sections use AppDecorations.card for visual consistency.
//            Reached via GoRouter /profile from AppNavShell side rail.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_nav.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bookings/data/booking_model.dart';
import '../../bookings/providers/bookings_providers.dart';
import '../../notifications/providers/notification_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

const double _kHorizPad = 20.0;
const double _kSectionGap = 20.0;
const double _kAvatarSize = 72.0;

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  final bool isTrainerView;
  const ProfileScreen({super.key, this.isTrainerView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);

    return userAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return AppNavShell(
          currentRoute: '/profile',
          isTrainerView: isTrainerView,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          child: _ProfileBody(user: user),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileBody
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider).valueOrNull ?? [];
    final upcoming = ref.watch(myUpcomingBookingsProvider).length;
    final total =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final cancelled = ref.watch(myCancelledBookingsProvider).length;

    return AppCanvas(
      type: BackgroundType.meshParticle,
      particleStyle: ParticleStyle.drift,
      gradientStyle: GradientStyle.pulse,
      child: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: _kHorizPad, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(children: [
                const HamburgerButton(),
                const SizedBox(width: 8),
                Text('Profile & Settings', style: AppTypography.h2),
              ]),

              const SizedBox(height: _kSectionGap),

              // ── Profile card ───────────────────────────────────────────
              _ProfileCard(user: user),

              const SizedBox(height: _kSectionGap),

              // ── Booking summary ────────────────────────────────────────
              _BookingSummaryStrip(
                upcoming: upcoming,
                total: total,
                cancelled: cancelled,
              ),

              const SizedBox(height: _kSectionGap),

              // ── Notification preferences ───────────────────────────────
              _NotificationSection(),

              const SizedBox(height: _kSectionGap),

              // ── Account section ────────────────────────────────────────
              _AccountSection(user: user),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileCard
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  const _ProfileCard({required this.user});

  String get _initials {
    final parts = user.displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardElevated,
      child: Row(
        children: [
          // Avatar
          Container(
            width: _kAvatarSize,
            height: _kAvatarSize,
            decoration: BoxDecoration(
              gradient: AppGradients.avatar,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.buttonGlow,
            ),
            child: Center(
              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        user.photoUrl!,
                        width: _kAvatarSize,
                        height: _kAvatarSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(_initials,
                            style: AppTypography.h2
                                .copyWith(color: AppColors.onPrimary)),
                      ),
                    )
                  : Text(_initials,
                      style: AppTypography.h2
                          .copyWith(color: AppColors.onPrimary)),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName,
                    style: AppTypography.h3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(user.email,
                    style: AppTypography.helper
                        .copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pillBR,
                  ),
                  child: Text('WellPath Member',
                      style: AppTypography.badge
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BookingSummaryStrip
// ─────────────────────────────────────────────────────────────────────────────

class _BookingSummaryStrip extends StatelessWidget {
  final int upcoming, total, cancelled;
  const _BookingSummaryStrip({
    required this.upcoming,
    required this.total,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card,
      child: Row(children: [
        Expanded(
            child: _StatCell(
                value: '$upcoming',
                label: 'Upcoming',
                color: AppColors.primary)),
        _Divider(),
        Expanded(
            child: _StatCell(
                value: '$total',
                label: 'Total\nSessions',
                color: AppColors.secondary)),
        _Divider(),
        Expanded(
            child: _StatCell(
                value: '$cancelled',
                label: 'Cancelled',
                color: cancelled > 0 ? AppColors.error : AppColors.textMuted)),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: AppTypography.h2.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style:
                AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppColors.border);
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotificationSection
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationSection extends ConsumerWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(children: [
            Icon(Icons.notifications_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Notifications', style: AppTypography.h4),
          ]),
        ),
        Container(
          decoration: AppDecorations.card,
          child: prefsAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Could not load preferences.'),
            ),
            data: (prefs) => Column(
              children: [
                _PrefGroup(title: 'Session Reminders', children: [
                  _PrefToggle(
                    icon: Icons.access_alarm_rounded,
                    title: '24 hours before',
                    subtitle: 'Get ready a day in advance',
                    value: prefs.sessionReminder24h,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .toggleSessionReminder24h(v),
                  ),
                  _PrefToggle(
                    icon: Icons.timer_rounded,
                    title: '1 hour before',
                    subtitle: 'Last-minute heads-up',
                    value: prefs.sessionReminder1h,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .toggleSessionReminder1h(v),
                  ),
                ]),
                Divider(height: 1, color: AppColors.border),
                _PrefGroup(title: 'Booking Activity', children: [
                  _PrefToggle(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Booking confirmations',
                    subtitle: 'When a session is confirmed',
                    value: prefs.bookingConfirmations,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .toggleBookingConfirmations(v),
                  ),
                  _PrefToggle(
                    icon: Icons.cancel_outlined,
                    title: 'Cancellation alerts',
                    subtitle: 'When trainer cancels your session',
                    value: prefs.cancellationAlerts,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .toggleCancellationAlerts(v),
                  ),
                ]),
                Divider(height: 1, color: AppColors.border),
                _PrefGroup(title: 'Wellness', children: [
                  _PrefToggle(
                    icon: Icons.water_drop_rounded,
                    title: 'Daily wellness reminder',
                    subtitle: 'Log workout, water & sleep',
                    value: prefs.wellnessReminder,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .toggleWellnessReminder(v),
                  ),
                  _PrefToggle(
                    icon: Icons.emoji_events_rounded,
                    title: 'Weekly goals summary',
                    subtitle: 'Progress review every Monday',
                    value: prefs.weeklyGoalsSummary,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .toggleWeeklyGoalsSummary(v),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrefGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _PrefGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title,
                style: AppTypography.overline
                    .copyWith(color: AppColors.textMuted, letterSpacing: 0.8)),
          ),
          ...children,
        ],
      );
}

class _PrefToggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceMid,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 16,
                color: value ? AppColors.primary : AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h5),
                Text(subtitle,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceMid,
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _AccountSection
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSection extends ConsumerWidget {
  final UserModel user;
  const _AccountSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(children: [
            Icon(Icons.manage_accounts_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Account', style: AppTypography.h4),
          ]),
        ),
        Container(
          decoration: AppDecorations.card,
          child: Column(children: [
            _AccountRow(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent to ${user.email}.',
                        style: AppTypography.helper),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                ref
                    .read(authRepositoryProvider)
                    .sendPasswordResetEmail(user.email);
              },
            ),
            Divider(height: 1, color: AppColors.border),
            _AccountRow(
              icon: Icons.info_outline_rounded,
              label: 'About WellPath',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'WellPath',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 WellPath. '
                    'All rights reserved.',
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            _AccountRow(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ]),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 17, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTypography.body
                      .copyWith(color: color ?? AppColors.textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ]),
        ),
      );
}
