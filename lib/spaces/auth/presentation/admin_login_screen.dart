// lib/spaces/auth/presentation/admin_login_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial implementation. Dedicated admin portal login screen.
//            Visually distinct from the user login: shield badge, warning-amber
//            accent, "Restricted Access" messaging, no sign-up affordance,
//            no image panel (single-column always — admin use is deliberate,
//            not discovery-driven).
//            Two-stage auth: Firebase signIn() → Firestore role check.
//            Non-admin accounts are signed out immediately with a clear error.
//            GoRouter redirect handles navigation to /admin on confirmed success.
// ─────────────────────────────────────────────────────────────────────────────
//
// ADMIN AUTH FLOW (why two stages):
//   Stage 1 — Firebase Auth signIn(). Proves the credentials are valid.
//   Stage 2 — Firestore users/{uid} role check. Proves the account has admin
//              rights. Without stage 2, ANY valid Firebase Auth user could reach
//              /admin if they knew the route — even if their role is 'user'.
//
//   On role mismatch: signOut() is called immediately before showing the error.
//   This ensures no authenticated session lingers for a non-admin caller.
//
// ADMIN ACCOUNT PROVISIONING:
//   Admin accounts are NOT created through the public signup flow.
//   They are provisioned in one of two ways:
//
//   Option A — Firebase Console (manual):
//     1. Authentication → Add user → enter email + password
//     2. Firestore → users/{uid} → Create document with:
//          { uid, email, displayName, role: 'admin', createdAt, updatedAt,
//            preferences: { dailyReminderEnabled: false, reminderTime: '20:00' } }
//
//   Option B — Cloud Function (programmatic):
//     Call setUserRole({ uid, role: 'admin' }) — sets custom claim + updates
//     the Firestore document. This function already exists in the project.
//
// CODESPACE RULES:
//   File path on line 1 ✓  |  CHANGELOG ✓  |  CONFIG BLOCK ✓
//   Comments explain WHY ✓  |  Complete file ✓

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../../../core/style/app_branding.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const double kAdminFormMaxWidth   = 400.0;
const double kAdminFormPaddingH   = 36.0;
const double kAdminFormPaddingV   = 52.0;
const double kAdminShieldBoxSize  = 56.0;
const double kAdminShieldIconSize = 26.0;
const double kAdminShieldRadius   = 16.0;

// Warning amber alpha values — keep these subtle.
// Too vivid and it looks alarming; too muted and the admin distinction is lost.
const double kAdminAccentBgAlpha     = 0.10; // shield container fill
const double kAdminAccentBorderAlpha = 0.28; // shield container border
const double kAdminAccentTextAlpha   = 0.65; // "Restricted Access" caption
const double kAdminAccentIconAlpha   = 0.90; // shield icon

// Set to false before shipping to production.
// While true, the real exception message surfaces in the error banner.
const bool kDevMode = true;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailController  = TextEditingController();
  final _pwController     = TextEditingController();

  bool    _isLoading    = false;
  String? _errorMessage;

  final _emailFocus = FocusNode();
  final _pwFocus    = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  //
  // Two-stage auth:
  //   1. Firebase signIn() — proves credentials are valid
  //   2. Firestore role check — proves the account has 'admin' role
  //
  // If stage 2 fails, signOut() is called before the error is displayed.
  // The GoRouter redirect guard handles navigation after a confirmed success.

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      // ── Stage 1: Firebase Auth ──────────────────────────────────────────
      final credential = await ref.read(authRepositoryProvider).signIn(
        email:    _emailController.text.trim(),
        password: _pwController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Firebase returned a null UID after sign-in.');

      // ── Stage 2: Firestore role check ───────────────────────────────────
      // .first gets one emission and closes the stream — a one-shot fetch.
      // We don't use firestoreUserProvider here because the Riverpod stream
      // may not have initialised yet for the freshly-signed-in user.
      final userModel = await ref
          .read(authRepositoryProvider)
          .userStream(uid)
          .first;

      if (userModel?.isAdmin != true) {
        // Not an admin — revoke the session immediately and surface the error.
        // This prevents a non-admin from having any authenticated state after
        // this screen rejects them.
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          setState(() => _errorMessage =
              'This account does not have admin access. '
              'Contact your system administrator to request access.');
        }
        return;
      }

      // Stage 2 confirmed — admin role verified.
      // GoRouter's authStateProvider + firestoreUserProvider redirect guard
      // fires automatically and routes the user to /admin.
      // No explicit context.go() needed here.

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    } catch (e, stack) {
      debugPrint('[AdminLoginScreen] error: $e');
      debugPrint('$stack');
      setState(() => _errorMessage = kDevMode
          ? 'DEBUG: $e'
          : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with these credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Connection error. Check your internet connection.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      default:
        return 'Firebase error: $code';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppCanvas(
        type:          BackgroundType.meshParticle,
        particleStyle: ParticleStyle.drift,
        gradientStyle: GradientStyle.pulse,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kAdminFormMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: kAdminFormPaddingH,
                  vertical:   kAdminFormPaddingV,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ── Shield badge + header ──────────────────────────
                      Center(child: _AdminShieldBadge()),
                      const SizedBox(height: 20),
                      Center(
                        child: BrandLogoEngine.verticalColored(),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Admin Portal',
                          style: AppTypography.h4.copyWith(
                            color:      AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Restricted Access  ·  Authorized Personnel Only',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning.withValues(
                              alpha: kAdminAccentTextAlpha,
                            ),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),

                      // ── Email ──────────────────────────────────────────
                      WellPathField(
                        controller:      _emailController,
                        label:           'Admin Email',
                        focusNode:       _emailFocus,
                        keyboardType:    TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofocus:       true,
                        onEditingComplete: () => _pwFocus.requestFocus(),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.textMuted,
                          size:  20,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // ── Password ───────────────────────────────────────
                      WellPathField(
                        controller:      _pwController,
                        label:           'Admin Password',
                        obscureText:     true,
                        focusNode:       _pwFocus,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _submit,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                          size:  20,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // ── Error banner ───────────────────────────────────
                      if (_errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 6,
                            vertical:   AppSpacing.sm + 2,
                          ),
                          decoration: AppDecorations.errorBanner,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size:  16,
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.helper
                                      .copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm + 4),
                      ],

                      // ── CTA button ─────────────────────────────────────
                      WellPathButton(
                        label:     'Sign In as Admin',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _submit,
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // ── Separator + provisioning note ──────────────────
                      // A subtle visual divider to separate the form from the
                      // informational footer. Reinforces that this is a
                      // controlled-access portal, not an open signup flow.
                      const WellPathDivider(label: 'ADMIN PORTAL'),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Admin access is restricted to authorized personnel.\n'
                        'Accounts are provisioned internally — '
                        'contact your system administrator for access.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color:  AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // ── Back to site ───────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/landing'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                size:  14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Back to WellPath',
                                style: AppTypography.caption.copyWith(
                                  color:    AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdminShieldBadge
// ─────────────────────────────────────────────────────────────────────────────
//
// A rounded container with a warning-amber tint that holds the shield icon.
// The amber hue is deliberately different from the brand green — it signals
// "this area requires elevated privileges" without being alarming.
// Alpha values are tuned low so it reads as institutional, not dangerous.

class _AdminShieldBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:  kAdminShieldBoxSize,
      height: kAdminShieldBoxSize,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: kAdminAccentBgAlpha),
        borderRadius: BorderRadius.circular(kAdminShieldRadius),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: kAdminAccentBorderAlpha),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.admin_panel_settings_rounded,
          size:  kAdminShieldIconSize,
          color: AppColors.warning.withValues(alpha: kAdminAccentIconAlpha),
        ),
      ),
    );
  }
}