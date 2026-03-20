// lib/features/home/home_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Auth verification screen. Shows live Firestore document fields
//            to confirm the full auth pipeline is working end-to-end.
//            Replace with real HomeScreen / TrainerDashboard in Week 3.
//   v1.1.0 — Fixed invalid_constant: removed const from Center wrapping
//            CircularProgressIndicator — AppColors.primary is a computed
//            getter, not a compile-time constant.
//          — AppColors.active → AppColors.tertiary everywhere.
//            app_theme.dart has no `active` token; `tertiary` is the
//            equivalent warm-accent / live highlight color.
// ─────────────────────────────────────────────────────────────────────────────
//
// VERIFICATION GUIDE — after a successful signup you should see:
//   ✓ UID populated       → Firebase Auth step 1 worked
//   ✓ Email populated     → step 1 worked
//   ✓ displayName filled  → Firestore step 3 written (source of truth)
//   ✓ role: user          → kDefaultRole written correctly
//   ✓ preferences shown   → UserPreferences.defaults() serialised correctly
//   ✓ Sign Out → /landing → GoRouter redirect + firestoreUserProvider reset OK

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_background.dart';

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  final bool isTrainerView;
  const HomeScreen({super.key, this.isTrainerView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firestoreUserProvider);

    return Scaffold(
      body: AppBackground(
        type:          BackgroundType.meshParticle,
        particleStyle: ParticleStyle.drift,
        gradientStyle: GradientStyle.pulse,
        child: SafeArea(
          child: userAsync.when(
            loading: () => Center(
              // ⚠ Do NOT add `const` here.
              // AppColors.primary is a computed getter (_Engine.darkBackground
              // chain), not a compile-time constant. Adding const propagates
              // to CircularProgressIndicator and causes an invalid_constant error.
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading user data:\n$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ),
            data: (user) {
              if (user == null) {
                // Firestore document missing. This shouldn't happen after the
                // Bug 1 fix (updateDisplayName try-catch). If seen, check that
                // auth_repository.dart step 3 completed without throwing.
                return const Center(
                  child: Text(
                    'User document not found in Firestore.\n'
                    'Check the console for signUp step 3 errors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0x8AFFFFFF), fontSize: 13),
                  ),
                );
              }

              return _HomeContent(
                user:          user,
                isTrainerView: isTrainerView,
                onSignOut: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  // GoRouter authStateProvider redirect handles navigation.
                  // No explicit context.go() needed.
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeContent
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final UserModel    user;
  final bool         isTrainerView;
  final VoidCallback onSignOut;

  const _HomeContent({
    required this.user,
    required this.isTrainerView,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTrainerView ? 'Trainer Dashboard' : 'Home',
                      style: AppTypography.h2.copyWith(
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⚠️  Auth verification screen — replace in Week 3',
                      style: AppTypography.helper.copyWith(
                        // AppColors.tertiary = warm coral accent (live/highlight).
                        // app_theme.dart has no `active` token — use tertiary.
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_outlined),
                color: AppColors.textSecondary,
                tooltip: 'Sign out',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Firestore document dump ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Auth pipeline verified',
                      style: AppTypography.helper.copyWith(
                        color:      AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _InfoRow(label: 'UID',          value: user.uid),
                _InfoRow(label: 'Email',         value: user.email),
                _InfoRow(
                  label: 'Display Name',
                  value: user.displayName.isEmpty
                      ? '(empty — Bug 1 fix still needed)'
                      : user.displayName,
                ),
                _InfoRow(
                  label:     'Role',
                  value:     user.role,
                  highlight: user.isTrainer,
                ),
                _InfoRow(
                  label: 'Photo URL',
                  value: user.photoUrl ?? '(none)',
                ),
                _InfoRow(
                  label: 'Created At',
                  value: user.createdAt?.toString() ?? '(null — check serverTimestamp)',
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                Text(
                  'preferences',
                  style: AppTypography.helper.copyWith(
                      color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Daily Reminder',
                  value: user.preferences.dailyReminderEnabled.toString(),
                ),
                _InfoRow(
                  label: 'Reminder Time',
                  value: user.preferences.reminderTime,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Navigation stubs ─────────────────────────────────────────────
          Text(
            'Navigation',
            style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _NavChip(label: 'Profile',  route: '/profile',  ctx: context),
              _NavChip(label: 'Bookings', route: '/bookings', ctx: context),
              _NavChip(label: 'Wellness', route: '/wellness', ctx: context),
              if (user.isTrainer)
                _NavChip(
                    label: 'Home (user)', route: '/home', ctx: context),
            ],
          ),

          const SizedBox(height: 32),

          // ── Sign-out CTA ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillBR),
              ),
              child: Text(
                'Sign Out',
                style: AppTypography.button.copyWith(
                  color:      AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.helper.copyWith(
                  color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.helper.copyWith(
                // AppColors.tertiary replaces the old AppColors.active
                // (which doesn't exist in app_theme.dart).
                color: highlight
                    ? AppColors.tertiary
                    : AppColors.textPrimary,
                fontWeight:
                    highlight ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String       label;
  final String       route;
  final BuildContext ctx;

  const _NavChip({
    required this.label,
    required this.route,
    required this.ctx,
  });

  @override
  Widget build(BuildContext _) {
    return ActionChip(
      label: Text(label),
      labelStyle: AppTypography.helper.copyWith(
          color: AppColors.textPrimary),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.inputBR),
      onPressed: () => ctx.push(route),
    );
  }
}