// lib/spaces/auth/presentation/admin_login_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.0.0 — Initial. Two-stage auth (Firebase + Firestore role check).
//   v1.0.1 — Shield badge removed. Switched to horizontal SVG logo.
//   v1.0.2 — "ADMIN PORTAL" amber pill badge added ABOVE the logo.
//            "Not an admin? Sign in as a regular user" link added at the
//            bottom — routes to /login. Styled subtly; not a primary action.
// ─────────────────────────────────────────────────────────────────────────────
//
// ADMIN AUTH FLOW (two stages, both required):
//   Stage 1 — Firebase Auth signIn() → proves credentials are valid.
//   Stage 2 — Firestore users/{uid} role check → proves role == 'admin'.
//   On failure at stage 2: signOut() is called before the error surfaces —
//   no authenticated session lingers for a non-admin caller.
//
// ADMIN ACCOUNT PROVISIONING:
//   Option A (Firebase Console): Auth → Add user, then Firestore users/{uid}
//     with role: 'admin' + standard fields.
//   Option B (Cloud Function): setUserRole({ uid, role: 'admin' }).
//
// CODESPACE RULES: File path line 1 ✓ | CHANGELOG ✓ | CONFIG BLOCK ✓ |
//   Comments explain WHY ✓ | Complete file ✓

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const String _kLogoHorizontal =
    'assets/logos/20260326_wellpath_logo_horizontal_primary_color.svg';

const double kAdminFormMaxWidth = 400.0;
const double kAdminFormPaddingH = 36.0;
const double kAdminFormPaddingV = 52.0;

// Amber alpha values.
// Low alphas are intentional — 'institutional', not 'alarming'.
// The amber hue alone carries the distinction from the brand-green user login.
const double kAdminPillBgAlpha     = 0.14; // pill fill
const double kAdminPillBorderAlpha = 0.32; // pill border
const double kAdminPillIconAlpha   = 0.85; // pill icon
const double kAdminPillTextAlpha   = 0.90; // pill label text
const double kAdminCaptionAlpha    = 0.60; // "Restricted Access" caption

// Set to false before shipping to production.
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
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pwController    = TextEditingController();

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Stage 1: Firebase Auth
      final credential = await ref.read(authRepositoryProvider).signIn(
        email:    _emailController.text.trim(),
        password: _pwController.text,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Firebase returned a null UID.');

      // Stage 2: Firestore role check
      // .first is a one-shot fetch — firestoreUserProvider may not have
      // initialised for the freshly-signed-in user yet.
      final userModel = await ref
          .read(authRepositoryProvider)
          .userStream(uid)
          .first;

      if (userModel?.isAdmin != true) {
        // Revoke immediately — no session for a non-admin.
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          setState(() => _errorMessage =
              'This account does not have admin access. '
              'Contact your system administrator to request access.');
        }
        return;
      }
      // Admin confirmed — GoRouter fires and routes to /admin automatically.

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    } catch (e, stack) {
      debugPrint('[AdminLoginScreen] $e\n$stack');
      setState(() => _errorMessage =
          kDevMode ? 'DEBUG: $e' : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(String code) => switch (code) {
    'user-not-found'         => 'No account found with these credentials.',
    'invalid-credential'     => 'No account found with these credentials.',
    'wrong-password'         => 'Incorrect password. Please try again.',
    'invalid-email'          => 'Please enter a valid email address.',
    'too-many-requests'      => 'Too many failed attempts. Wait a few minutes.',
    'network-request-failed' => 'Connection error. Check your internet.',
    'user-disabled'          => 'This admin account has been disabled.',
    _                        => 'Firebase error: $code',
  };

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

                      // ── 1. ADMIN PORTAL pill badge ─────────────────────
                      // Amber pill above the logo: visitor reads context
                      // ("ADMIN PORTAL") → product ("WellPath") → restriction
                      // ("Restricted Access…") in a natural top-down flow.
                      Center(child: _AdminPortalPill()),
                      const SizedBox(height: 16),

                      // ── 2. WellPath horizontal logo ────────────────────
                      Center(
                        child: SvgPicture.asset(
                          _kLogoHorizontal,
                          width: 200,
                          fit:   BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── 3. Restricted access caption ───────────────────
                      Center(
                        child: Text(
                          'Restricted Access  ·  Authorized Personnel Only',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning.withValues(
                              alpha: kAdminCaptionAlpha,
                            ),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),

                      // ── 4. Email ───────────────────────────────────────
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
                          color: AppColors.textMuted, size: 20,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // ── 5. Password ────────────────────────────────────
                      WellPathField(
                        controller:      _pwController,
                        label:           'Admin Password',
                        obscureText:     true,
                        focusNode:       _pwFocus,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _submit,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted, size: 20,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // ── 6. Error banner ────────────────────────────────
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
                                child: Icon(Icons.error_outline,
                                    color: AppColors.error, size: 16),
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

                      // ── 7. CTA button ──────────────────────────────────
                      WellPathButton(
                        label:     'Sign In as Admin',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _submit,
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // ── 8. Separator + provisioning note ───────────────
                      const WellPathDivider(label: 'ADMIN PORTAL'),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Admin access is restricted to authorized personnel.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted, height: 1.5,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // ── 9. "Sign in as regular user" link ──────────────
                      // Subtle secondary action — for visitors who landed here
                      // by mistake, or admins who also have regular accounts.
                      // Not styled as a button; it should not compete with the
                      // primary CTA.
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text:  'Not an admin?  ',
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              TextSpan(
                                text:  'Sign in as a regular user',
                                style: AppTypography.caption.copyWith(
                                  color:      AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),

                      // ── 10. Back to site ───────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/landing'),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.arrow_back_rounded,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              'Back to WellPath',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted, fontSize: 12,
                              ),
                            ),
                          ]),
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
// _AdminPortalPill
// ─────────────────────────────────────────────────────────────────────────────
//
// Amber pill badge. Positioned ABOVE the WellPath logo so the information
// hierarchy reads: context ("ADMIN PORTAL") → product ("WellPath") →
// access note ("Restricted Access…").
//
// The amber hue is deliberately different from the brand green so the admin
// portal is unmistakably distinct from the regular login — without being
// alarmist. Low alpha values keep the tone institutional.

class _AdminPortalPill extends StatelessWidget {
  const _AdminPortalPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color:        AppColors.warning.withValues(alpha: kAdminPillBgAlpha),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: kAdminPillBorderAlpha),
          width: 1.0,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          size:  11,
          color: AppColors.warning.withValues(alpha: kAdminPillIconAlpha),
        ),
        const SizedBox(width: 5),
        Text(
          'ADMIN PORTAL',
          style: AppTypography.overline.copyWith(
            color:         AppColors.warning.withValues(alpha: kAdminPillTextAlpha),
            fontSize:      9,
            fontWeight:    FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ]),
    );
  }
}