// lib/features/auth/presentation/login_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.2.0 — AppTextStyles.authSubheading fix. Import paths corrected.
//            sendPasswordResetEmail routed through AuthRepository.
//   v1.3.0 — Generic catch block now surfaces the REAL error in the UI
//            during development. Search for kDevMode to remove before prod.
// ─────────────────────────────────────────────────────────────────────────────

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

const double kLoginBreakpoint = 840.0;
const int kLoginFlexForm = 4;
const int kLoginFlexImage = 5;
const double kLoginFormMaxWidth = 420.0;
const double kLoginFormPaddingH = 36.0;
const double kLoginFormPaddingV = 48.0;

const double kLoginSubtitleSize = 14.0;
const String kLoginGifPath = 'gifs/login_digital_screen_male.gif';
const double kLoginImagePaddingH = 48.0;

// Set to false before shipping to production.
const bool kDevMode = true;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _resetSending = false;
  String? _errorMessage;

  final _emailFocus = FocusNode();
  final _pwFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // No context.go() — GoRouter authStateProvider redirect handles navigation.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    } catch (e, stack) {
      debugPrint('[LoginScreen] non-Firebase error: $e');
      debugPrint('$stack');
      setState(() => _errorMessage =
          kDevMode ? 'DEBUG: $e' : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage =
          'Enter your email address above, then tap Forgot password.');
      return;
    }
    setState(() {
      _resetSending = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email',
                style: AppTypography.helper),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    } catch (e, stack) {
      debugPrint('[LoginScreen] password reset error: $e\n$stack');
      setState(() => _errorMessage =
          kDevMode ? 'DEBUG: $e' : 'Could not send reset email. Try again.');
    } finally {
      if (mounted) setState(() => _resetSending = false);
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
        return 'Too many failed attempts. Wait a few minutes.';
      case 'network-request-failed':
        return 'Connection error. Check your internet.';
      default:
        return 'Firebase error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTwoColumn = MediaQuery.of(context).size.width >= kLoginBreakpoint;

    return Scaffold(
      body: AppCanvas(
        type: BackgroundType.meshParticle,
        particleStyle: ParticleStyle.drift,
        gradientStyle: GradientStyle.pulse,
        child: SafeArea(
          child: isTwoColumn
              ? _TwoColumnLayout(
                  formPanel: _formPanel(),
                  imagePanel: const _ImagePanel(assetPath: kLoginGifPath),
                )
              : _SingleColumnLayout(formPanel: _formPanel()),
        ),
      ),
    );
  }

  Widget _formPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kLoginFormMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: kLoginFormPaddingH,
            vertical: kLoginFormPaddingV,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandLogoEngine.verticalColored(),
                SizedBox(height: AppSpacing.xs + 2),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.authSubheading.copyWith(
                    fontSize: kLoginSubtitleSize,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: AppSpacing.xxl - AppSpacing.md),
                WellPathField(
                  controller: _emailController,
                  label: 'Email',
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  onEditingComplete: () => _pwFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textMuted, size: 20),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),
                WellPathField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  focusNode: _pwFocus,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetSending ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.primary,
                    ),
                    child: _resetSending
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primary,
                            ),
                          )
                        : Text(
                            'Forgot password?',
                            style: AppTypography.helper.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 6,
                      vertical: AppSpacing.sm + 2,
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
                WellPathButton(
                  label: 'Log In',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
                SizedBox(height: AppSpacing.md + AppSpacing.xs),
                const WellPathDivider(),
                SizedBox(height: AppSpacing.md + AppSpacing.xs),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/signup'),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.authSubheading
                              .copyWith(fontSize: 13),
                        ),
                        TextSpan(
                          text: 'Sign up',
                          style: AppTextStyles.authSubheading.copyWith(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _TwoColumnLayout extends StatelessWidget {
  final Widget formPanel;
  final Widget imagePanel;
  const _TwoColumnLayout({required this.formPanel, required this.imagePanel});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(flex: kLoginFlexForm, child: formPanel),
        Expanded(flex: kLoginFlexImage, child: imagePanel),
      ]);
}

class _SingleColumnLayout extends StatelessWidget {
  final Widget formPanel;
  const _SingleColumnLayout({required this.formPanel});

  @override
  Widget build(BuildContext context) => formPanel;
}

class _ImagePanel extends StatelessWidget {
  final String assetPath;
  const _ImagePanel({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kLoginImagePaddingH),
          child: ClipRRect(
            borderRadius: AppRadius.cardBR,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textMuted, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
