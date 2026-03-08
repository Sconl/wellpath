// lib/features/auth/presentation/signup_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// SignupScreen — Feature 0 (Week 2)
//
// Layout:
//   • Wide screens (≥ 840 px): two-column split
//       Left  — illustrated GIF panel (signup_digital_screen_female.gif)
//       Right — form panel
//   • Narrow screens (<  840 px): single-column, form only
//
// Background: WellPathBackground (animated gradient + particles).
// Form state:  Riverpod ConsumerStatefulWidget.
// Navigation:  GoRouter — success → '/home', link → '/login'.
//
// GIF asset:
//   assets/animated-gifs/signup_digital_screen_female.gif
//   (declare in pubspec.yaml under flutter › assets)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/wellpath_background.dart';
import '../auth_providers.dart';                        // authRepositoryProvider
import 'widgets/auth_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey               = GlobalKey<FormState>();
  final _nameController        = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPasswordCtrl   = TextEditingController();

  // ── UI State ──────────────────────────────────────────────────────────────
  bool    _isLoading    = false;
  String? _errorMessage;

  // ── Focus nodes for keyboard-next traversal ────────────────────────────────
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _pwFocus      = FocusNode();
  final _cpwFocus     = FocusNode();

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

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
        email:       _emailController.text.trim(),
        password:    _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(String code) {
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
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTwoColumn = screenWidth >= 840;

    return Scaffold(
      body: WellPathBackground(
        child: SafeArea(
          child: isTwoColumn
              ? _TwoColumnLayout(formPanel: _formPanel())
              : _SingleColumnLayout(formPanel: _formPanel()),
        ),
      ),
    );
  }

  // ── Form panel (shared between both layouts) ───────────────────────────────

  Widget _formPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Brand ────────────────────────────────────────────────
                const WellPathLogo(fontSize: 36),
                const SizedBox(height: 6),
                Text(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Display Name ─────────────────────────────────────────
                WellPathField(
                  controller:        _nameController,
                  label:             'Display Name',
                  focusNode:         _nameFocus,
                  textInputAction:   TextInputAction.next,
                  onEditingComplete: () => _emailFocus.requestFocus(),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
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
                const SizedBox(height: 16),

                // ── Email ────────────────────────────────────────────────
                WellPathField(
                  controller:        _emailController,
                  label:             'Email',
                  focusNode:         _emailFocus,
                  keyboardType:      TextInputType.emailAddress,
                  textInputAction:   TextInputAction.next,
                  onEditingComplete: () => _pwFocus.requestFocus(),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailReg.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────
                WellPathField(
                  controller:        _passwordController,
                  label:             'Password',
                  obscureText:       true,
                  focusNode:         _pwFocus,
                  textInputAction:   TextInputAction.next,
                  onEditingComplete: () => _cpwFocus.requestFocus(),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ─────────────────────────────────────
                WellPathField(
                  controller:        _confirmPasswordCtrl,
                  label:             'Confirm Password',
                  obscureText:       true,
                  focusNode:         _cpwFocus,
                  textInputAction:   TextInputAction.done,
                  onEditingComplete: _submit,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Inline error ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.redAccent.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── CTA ──────────────────────────────────────────────────
                WellPathButton(
                  label:     'Create Account',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),

                // ── Navigate to Login ────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          TextSpan(
                            text: 'Log in',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF00CC66),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

/// Desktop two-column: illustrated left panel + form right panel.
class _TwoColumnLayout extends StatelessWidget {
  final Widget formPanel;

  const _TwoColumnLayout({required this.formPanel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left: illustration panel ───────────────────────────────────
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0x22FFFFFF)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GIF illustration
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/animated-gifs/signup_digital_screen_female.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Join WellPath and start your\nfitness journey today.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Feature pills
                const Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _FeaturePill('🏋️ Discover Trainers'),
                    _FeaturePill('📅 Book Sessions'),
                    _FeaturePill('💧 Track Wellness'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Right: form panel ──────────────────────────────────────────
        Expanded(
          flex: 4,
          child: formPanel,
        ),
      ],
    );
  }
}

/// Mobile single-column: form panel only.
class _SingleColumnLayout extends StatelessWidget {
  final Widget formPanel;

  const _SingleColumnLayout({required this.formPanel});

  @override
  Widget build(BuildContext context) {
    return formPanel;
  }
}

// Small decorative pill for the illustration panel
class _FeaturePill extends StatelessWidget {
  final String label;

  const _FeaturePill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00CC66).withAlpha(20),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF00CC66).withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: const Color(0xFF00CC66),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}