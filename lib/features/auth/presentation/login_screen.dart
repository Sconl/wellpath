// lib/features/auth/presentation/login_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — Feature 0 (Week 2)
//
// Layout:
//   • Wide screens (≥ 840 px): two-column split
//       Left  — illustrated GIF panel (login_digital_screen_male.gif)
//       Right — form panel
//   • Narrow screens (<  840 px): single-column, form only
//
// Background: WellPathBackground (animated gradient + particles).
// Form state:  Riverpod ConsumerStatefulWidget.
// Navigation:  GoRouter — success → redirect handled by authStateProvider,
//              link to '/signup', forgot-password SnackBar.
//
// Post-login role routing:
//   role == 'trainer' → '/trainer-dashboard'
//   else              → '/home'
//   (GoRouter redirect guard reads authStateProvider + firestoreUserProvider)
//
// GIF asset:
//   assets/animated-gifs/login_digital_screen_male.gif
//   (declare in pubspec.yaml under flutter › assets)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/wellpath_background.dart';
import '../auth_providers.dart'; // authRepositoryProvider
import 'widgets/auth_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── UI State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _resetSending = false;
  String? _errorMessage;

  // ── Focus nodes ───────────────────────────────────────────────────────────
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

  // ── Sign-in ────────────────────────────────────────────────────────────────

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
      // GoRouter's authStateProvider redirect guard handles navigation.
      // No explicit context.go() here — avoids double-navigate race.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.code));
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────

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
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to $email',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF0A1F12),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.code));
    } finally {
      if (mounted) setState(() => _resetSending = false);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes.';
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

  // ── Form panel ─────────────────────────────────────────────────────────────

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
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Email ────────────────────────────────────────────────
                WellPathField(
                  controller: _emailController,
                  label: 'Email',
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  onEditingComplete: () => _pwFocus.requestFocus(),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────
                WellPathField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  focusNode: _pwFocus,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white38,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                // ── Forgot password ──────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetSending ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _resetSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF00CC66),
                            ),
                          )
                        : Text(
                            'Forgot password?',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF00CC66),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Inline error ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withAlpha(60)),
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
                  label: 'Log In',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),

                // ── Divider ──────────────────────────────────────────────
                const WellPathDivider(),
                const SizedBox(height: 20),

                // ── Navigate to Signup ───────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/signup'),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          TextSpan(
                            text: 'Sign up',
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
                      'assets/animated-gifs/sample.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Your fitness journey\ncontinues here.',
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
                // Stat pills
                const Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatPill('🏆 Track Progress'),
                    _StatPill('📲 Instant Booking'),
                    _StatPill('🔔 Smart Reminders'),
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

class _StatPill extends StatelessWidget {
  final String label;

  const _StatPill(this.label);

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
