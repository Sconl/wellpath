// lib/features/auth/presentation/signup_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v1.2.0 — AppTextStyles.authSubheading fix. Import paths corrected.
//   v1.3.0 — Generic catch block now surfaces the REAL error in the UI
//            during development (not just in the console). This makes the
//            "something went wrong" mystery self-diagnosing — you see the
//            actual exception message directly on screen.
//            Search for kDevMode to remove this before production.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/style/app_canvas.dart';
import '../../../core/style/app_decorations.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

const double kSignupBreakpoint = 840.0;
const int kSignupFlexForm = 4;
const int kSignupFlexImage = 5;
const double kSignupFormMaxWidth = 420.0;
const double kSignupFormPaddingH = 36.0;
const double kSignupFormPaddingV = 40.0;
const double kSignupLogoSize = 36.0;
const double kSignupSubtitleSize = 14.0;
const String kSignupGifPath = 'animated-gifs/signup_digital_screen_female.gif';
const double kSignupImagePaddingH = 48.0;

// Set to false before shipping to production.
// While true, the real exception message is shown in the error banner
// so you don't have to hunt through the console to diagnose failures.
const bool kDevMode = true;

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _cpwFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _pwFocus.dispose();
    _cpwFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
      // No context.go() — GoRouter authStateProvider redirect handles navigation.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e.code));
    } catch (e, stack) {
      // In dev mode: show the real error on screen so you can diagnose without
      // needing to find it in the console. Remove kDevMode before production.
      debugPrint('[SignupScreen] non-Firebase error: $e');
      debugPrint('$stack');
      setState(() => _errorMessage =
          kDevMode ? 'DEBUG: $e' : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Connection error. Check your internet and try again.';
      default:
        return 'Firebase error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTwoColumn = MediaQuery.of(context).size.width >= kSignupBreakpoint;

    return Scaffold(
      body: AppCanvas(
        type: BackgroundType.meshParticle,
        particleStyle: ParticleStyle.drift,
        gradientStyle: GradientStyle.pulse,
        child: SafeArea(
          child: isTwoColumn
              ? _TwoColumnLayout(
                  formPanel: _formPanel(),
                  imagePanel: const _ImagePanel(assetPath: kSignupGifPath),
                )
              : _SingleColumnLayout(formPanel: _formPanel()),
        ),
      ),
    );
  }

  Widget _formPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kSignupFormMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: kSignupFormPaddingH,
            vertical: kSignupFormPaddingV,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WellPathLogo(fontSize: kSignupLogoSize),
                SizedBox(height: AppSpacing.xs + 2),
                Text(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.authSubheading.copyWith(
                    fontSize: kSignupSubtitleSize,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                WellPathField(
                  controller: _nameController,
                  label: 'Display Name',
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  onEditingComplete: () => _emailFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textMuted, size: 20),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (v.trim().length > 50) {
                      return 'Name must be under 50 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),
                WellPathField(
                  controller: _emailController,
                  label: 'Email',
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _pwFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textMuted, size: 20),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v.trim())) {
                      return 'Enter a valid email address';
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
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => _cpwFocus.requestFocus(),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 20),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),
                WellPathField(
                  controller: _confirmPasswordCtrl,
                  label: 'Confirm Password',
                  obscureText: true,
                  focusNode: _cpwFocus,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 20),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md + AppSpacing.xs),
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
                  label: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
                SizedBox(height: AppSpacing.md + AppSpacing.xs),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: AppTextStyles.authSubheading
                              .copyWith(fontSize: 13),
                        ),
                        TextSpan(
                          text: 'Log in',
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
        Expanded(flex: kSignupFlexForm, child: formPanel),
        Expanded(flex: kSignupFlexImage, child: imagePanel),
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
          padding: const EdgeInsets.symmetric(horizontal: kSignupImagePaddingH),
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
