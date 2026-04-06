// lib/core/widgets/developer_feedback_chat.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Initial creation — AI-powered feedback chat dialog using Gemini
//   • v2 — kFabSize ambiguous import fixed: now imports app_fab.dart directly
//   • v3 — three modes added: AI Assistant, Live Chat, Anonymous Feedback.
//     Mode state is maintained at the top level of State so the AI session
//     (ChatSession) survives tab switches and resumes exactly where it left off.
//   • v4 — lint cleanup:
//       - Removed unused _kLiveSendLabel and _kAnonSendLabel constants
//       - Removed all debug print() calls (avoid_print)
//       - Added curly braces to all if statements (curly_braces_in_flow_control_structures)
//       - Added const to all eligible constructors (prefer_const_constructors)
//       - Cleaned up initState — debug key-verification block removed
// ─────────────────────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════════════════════
// API KEY SETUP — REQUIRED BEFORE THE AI TAB WORKS
// ═════════════════════════════════════════════════════════════════════════════
//
// STEP 1 — Get a free Gemini API key
// ────────────────────────────────────
//   1. Go to https://aistudio.google.com/
//   2. Sign in with any Google account
//   3. Click "Get API key" → "Create API key in new project"
//   4. Copy the key (starts with "AIza...")
//   Free quota: 15 req/min, 1,500 req/day, 1M tokens/min
//
// STEP 2 — Run locally with the key
// ────────────────────────────────────
//   Quick Start (Recommended):
//   ──────────────────────────
//   ./flutter_run_chrome.sh     # Runs flutter run -d chrome with AI
//   ./flutter_build_web.sh      # Runs flutter build web with AI
//   ./deploy_with_ai.sh         # Builds and deploys with AI
//
//   Using the universal script:
//   ──────────────────────────
//   ./run_with_ai.sh run -d chrome
//   ./run_with_ai.sh build web --release
//
//   Manual commands:
//   ──────────────────────────
//   flutter run -d chrome --dart-define=GEMINI_API_KEY=AIzaYourKeyHere
//   flutter build web --dart-define=GEMINI_API_KEY=AIzaYourKeyHere
//
//   VS Code (alternative):
//   ──────────────────────
//   Use launch configurations in .vscode/launch.json
//   Select "WellPath (Chrome) - With AI"
//
// STEP 3 — Build and deploy to Firebase Hosting
// ───────────────────────────────────────────────
//   Quick deploy:
//   ────────────
//   ./deploy_with_ai.sh
//
//   GitHub Actions (CI/CD):
//   ──────────────────────
//   Push to dev/main branch - automatically deploys with AI
//   Requires GEMINI_API_KEY secret in GitHub repository settings
//
//   Manual steps:
//   ────────────
//   ./run_with_ai.sh build web --release
//   firebase deploy --only hosting
//
//   Or use deploy.sh in the project root:
//   ─────────────────────────────────────
//   export GEMINI_API_KEY=AIzaYourKeyHere
//   flutter build web --release --dart-define=GEMINI_API_KEY=${GEMINI_API_KEY}
//   firebase deploy --only hosting
//
// ⚠ PRODUCTION SECURITY
// ───────────────────────
//   --dart-define keys ARE visible in compiled JavaScript. Acceptable for a
//   student project. Before commercial launch, proxy via a Firebase Cloud
//   Function with the key stored in Firebase Secret Manager.
//
// RELIABILITY FEATURES
// ─────────────────────
//   • Automatic retry with exponential backoff (up to 3 attempts)
//   • 30-second timeout per request
//   • Graceful fallback messages when AI is unavailable
//   • Chat session persistence across tab switches
//   • API key validation with helpful error messages
//
// STEP 4 — pubspec.yaml dependency
// ──────────────────────────────────
//   dependencies:
//     google_generative_ai: ^0.4.6
//
// STEP 5 — Firestore security rules
// ───────────────────────────────────
//   match /feedback/{doc} {
//     allow create: if true;
//     allow read, update, delete: if false;
//   }
//
// ═════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../style/app_theme.dart';
import '../style/app_decorations.dart';
import 'app_fab.dart'; // for kFabSize — used for send button border-radius

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ── Gemini ────────────────────────────────────────────────────────────────────
const String _kGeminiModel = 'gemini-flash-latest';
const int _kMaxOutputTokens = 300;
const double _kTemperature = 0.7;
const int _kMaxRetries = 3;
const Duration _kRequestTimeout = Duration(seconds: 30);

// ── Internal markers ──────────────────────────────────────────────────────────
const String _kInitTrigger = '__START__';
const String _kSubmitMarker = 'SUBMIT_FEEDBACK|||';

// ── UI copy — AI tab ─────────────────────────────────────────────────────────
const String _kAiInputHint = 'Type a message...';
const String _kAiInputHintDone = 'Feedback submitted — thank you!';
const String _kNoApiKey = 'The AI assistant is not configured yet.\n\n'
    'To enable AI chat:\n'
    '1. Get a free Gemini API key from https://aistudio.google.com/\n'
    '2. Run the app with: flutter run --dart-define=GEMINI_API_KEY=your_key_here\n'
    '3. Or add it to your VS Code launch.json\n\n'
    'The setup guide is at the top of developer_feedback_chat.dart';

// ── UI copy — Live Chat tab ───────────────────────────────────────────────────
// _kLiveSendLabel removed — unused (button uses an icon, not a text label)
const String _kLiveTitle = 'Chat with a Human';
const String _kLiveDescription =
    'Leave your issue and optional contact details. '
    'The developer will review and respond within 48 hours.';
const String _kLiveMsgHint = 'Describe your issue or question...';
const String _kLiveContactHint = 'Email or WhatsApp (optional)';
const String _kLiveSuccess = '✅  Request sent. You\'ll hear back soon!';
const String _kLiveError = 'Failed to send. Please try again.';

// ── UI copy — Anonymous tab ───────────────────────────────────────────────────
// _kAnonSendLabel removed — unused (button uses an icon, not a text label)
const String _kAnonTitle = 'Anonymous Feedback';
const String _kAnonDescription =
    'No account, no name, no tracking. Your feedback is saved '
    'without any identifying information.';
const String _kAnonHint = 'Write your feedback here...';
const String _kAnonSuccess = '✅  Feedback received — thank you!';
const String _kAnonError = 'Failed to submit. Please try again.';

// ── AI system prompt ──────────────────────────────────────────────────────────
const String _kSystemPrompt = '''
You are a friendly feedback assistant for WellPath — a web-based integrated fitness and wellness platform currently in development.

Your mission: have a natural, helpful conversation to collect meaningful, actionable feedback.

Rules:
• Keep every response to 1–3 sentences. Never longer.
• Ask exactly ONE follow-up question per turn.
• Feedback categories: bug, feature, general, praise.
• After 3–5 productive exchanges, offer to submit the feedback.
• When the user confirms (yes / submit / go ahead / send it / sure / ok / done):
  Respond with EXACTLY this line and nothing else — no preamble, no closing:
  SUBMIT_FEEDBACK|||{"type":"bug|feature|general|praise","summary":"one sentence summary","details":"full context with specific details","sentiment":"positive|negative|neutral"}

When you receive __START__: greet the user warmly in 1–2 sentences and ask what they would like to share. Do not ask for their name.

Stay focused on WellPath. If asked unrelated questions, gently redirect.
''';

// ─────────────────────────────────────────────────────────────────────────────
// END CONFIG BLOCK
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Enums and data types
// ─────────────────────────────────────────────────────────────────────────────

enum _ChatMode { aiAssistant, liveChat, anonymous }

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class _FeedbackCategory {
  final String label;
  final IconData icon;
  final String value;
  const _FeedbackCategory({
    required this.label,
    required this.icon,
    required this.value,
  });
}

const List<_FeedbackCategory> _kCategories = [
  _FeedbackCategory(
      label: 'Bug', icon: Icons.bug_report_outlined, value: 'bug'),
  _FeedbackCategory(
      label: 'Feature', icon: Icons.lightbulb_outlined, value: 'feature'),
  _FeedbackCategory(
      label: 'General', icon: Icons.chat_outlined, value: 'general'),
  _FeedbackCategory(
      label: 'Praise', icon: Icons.thumb_up_alt_outlined, value: 'praise'),
];

// ─────────────────────────────────────────────────────────────────────────────
// DeveloperFeedbackChat
// ─────────────────────────────────────────────────────────────────────────────
//
// USAGE from any page:
//
//   AppFab(
//     icon:      Icons.chat_bubble_outline,
//     label:     'Feedback',
//     tooltip:   'Chat with our AI assistant to share feedback',
//     onPressed: () => showDialog(
//       context:      context,
//       barrierColor: AppColors.scrim,
//       builder: (_) => const DeveloperFeedbackChat(page: 'landing'),
//     ),
//   )

class DeveloperFeedbackChat extends StatefulWidget {
  final String page;
  const DeveloperFeedbackChat({super.key, this.page = 'unknown'});

  @override
  State<DeveloperFeedbackChat> createState() => _DeveloperFeedbackChatState();
}

class _DeveloperFeedbackChatState extends State<DeveloperFeedbackChat> {
  _ChatMode _mode = _ChatMode.aiAssistant;

  // ── AI tab ────────────────────────────────────────────────────────────────
  final List<_ChatMessage> _aiMessages = [];
  final TextEditingController _aiInputCtrl = TextEditingController();
  final ScrollController _aiScrollCtrl = ScrollController();
  final FocusNode _aiFocusNode = FocusNode();
  bool _aiTyping = false;
  bool _aiSubmitted = false;
  // ChatSession persists across tab switches so the AI remembers the conversation.
  ChatSession? _chat;

  // ── Live chat tab ─────────────────────────────────────────────────────────
  final TextEditingController _lcMsgCtrl = TextEditingController();
  final TextEditingController _lcContactCtrl = TextEditingController();
  bool _lcSending = false;
  bool _lcSent = false;

  // ── Anonymous tab ─────────────────────────────────────────────────────────
  final TextEditingController _anonCtrl = TextEditingController();
  String _anonCategory = 'general';
  bool _anonSending = false;
  bool _anonSent = false;

  bool get _apiKeyConfigured {
    final key = const String.fromEnvironment('GEMINI_API_KEY');
    return key.isNotEmpty && key.startsWith('AIza');
  }

  // API key validation for debugging
  void _validateApiKey() {
    final key = const String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      debugPrint(
          '❌ GEMINI_API_KEY not configured - AI chat will show setup instructions');
    } else if (!key.startsWith('AIza')) {
      debugPrint(
          '⚠️  GEMINI_API_KEY does not start with "AIza" - may be invalid');
    } else {
      debugPrint(
          '✅ GEMINI_API_KEY configured and appears valid (length: ${key.length})');
    }
  }

  // Public method to check AI readiness (can be called from outside)
  static bool isAiReady() {
    final key = const String.fromEnvironment('GEMINI_API_KEY');
    return key.isNotEmpty && key.startsWith('AIza');
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _validateApiKey();
    _initAiSession();
  }

  @override
  void dispose() {
    _aiInputCtrl.dispose();
    _aiScrollCtrl.dispose();
    _aiFocusNode.dispose();
    _lcMsgCtrl.dispose();
    _lcContactCtrl.dispose();
    _anonCtrl.dispose();
    super.dispose();
  }

  // ── AI session ─────────────────────────────────────────────────────────

  void _initAiSession() {
    if (!_apiKeyConfigured) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _aiMessages.add(
                _ChatMessage(text: _kNoApiKey, isUser: false),
              ));
        }
      });
      return;
    }

    try {
      final model = GenerativeModel(
        model: _kGeminiModel,
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
        systemInstruction: Content.system(_kSystemPrompt),
        generationConfig: GenerationConfig(
          maxOutputTokens: _kMaxOutputTokens,
          temperature: _kTemperature,
        ),
      );
      _chat = model.startChat();
      _triggerGreeting();
    } catch (e) {
      debugPrint('❌ Failed to initialize AI session: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _aiMessages.add(
                _ChatMessage(
                    text:
                        '⚠️ AI initialization failed. Please try again later.',
                    isUser: false),
              ));
        }
      });
    }
  }

  Future<void> _triggerGreeting() async {
    if (_chat == null) return;

    setState(() => _aiTyping = true);
    try {
      final response = await _chat!
          .sendMessage(Content.text(_kInitTrigger))
          .timeout(_kRequestTimeout);
      final text = response.text?.trim() ?? '';
      if (mounted) {
        setState(() {
          _aiTyping = false;
          if (text.isNotEmpty) {
            _aiMessages.add(_ChatMessage(text: text, isUser: false));
          } else {
            _aiMessages.add(_ChatMessage(
              text:
                  'Hi! I\'m here to help collect your feedback about WellPath. What\'s on your mind?',
              isUser: false,
            ));
          }
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _aiTyping = false;
          _aiMessages.add(_ChatMessage(
            text: '⚠️ AI response timed out. Please try again.',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      debugPrint('❌ Greeting failed: $e');
      if (mounted) {
        setState(() {
          _aiTyping = false;
          _aiMessages.add(_ChatMessage(
            text:
                'Hi! I\'m here to help collect your feedback about WellPath. What\'s on your mind — a bug, feature idea, or something else?',
            isUser: false,
          ));
        });
      }
    }
    _scrollAiToBottom();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_mode == _ChatMode.aiAssistant) {
        _aiFocusNode.requestFocus();
      }
    });
  }

  Future<void> _sendAiMessage() async {
    final text = _aiInputCtrl.text.trim();
    if (text.isEmpty || _aiTyping || _aiSubmitted || _chat == null) {
      return;
    }

    setState(() {
      _aiMessages.add(_ChatMessage(text: text, isUser: true));
      _aiTyping = true;
    });
    _aiInputCtrl.clear();
    _scrollAiToBottom();

    String? responseText;
    for (int attempt = 1; attempt <= _kMaxRetries; attempt++) {
      try {
        final response = await _chat!
            .sendMessage(Content.text(text))
            .timeout(_kRequestTimeout);
        responseText = response.text?.trim();
        break; // Success, exit retry loop
      } on TimeoutException {
        if (attempt == _kMaxRetries) {
          responseText =
              '⚠️ AI response timed out after $_kMaxRetries attempts. Please try again.';
        } else {
          debugPrint('⏳ AI request timeout (attempt $attempt), retrying...');
          await Future.delayed(
              Duration(milliseconds: 500 * attempt)); // Exponential backoff
        }
      } catch (e) {
        debugPrint('❌ AI request failed (attempt $attempt): $e');
        if (attempt == _kMaxRetries) {
          responseText =
              '⚠️ AI temporarily unavailable after $_kMaxRetries attempts. Please try again shortly.';
        } else {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    if (mounted) {
      setState(() => _aiTyping = false);

      if (responseText != null) {
        if (responseText.contains(_kSubmitMarker)) {
          await _processAiSubmission(responseText);
        } else if (responseText.isNotEmpty) {
          _aiMessages.add(_ChatMessage(text: responseText, isUser: false));
        }
      }
    }

    _scrollAiToBottom();
    if (!_aiSubmitted) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _aiFocusNode.requestFocus());
    }
  }

  Future<void> _processAiSubmission(String raw) async {
    final parts = raw.split(_kSubmitMarker);
    final jsonStr = parts.length > 1 ? parts.last.trim() : '';
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      await FirebaseFirestore.instance.collection('feedback').add({
        'timestamp': FieldValue.serverTimestamp(),
        'channel': 'ai_assistant',
        'page': widget.page,
        'type': data['type'] ?? 'general',
        'summary': data['summary'] ?? '',
        'details': data['details'] ?? '',
        'sentiment': data['sentiment'] ?? 'neutral',
        'status': 'new',
        'exchanges': _aiMessages.where((m) => m.isUser).length,
      });
      if (mounted) {
        setState(() {
          _aiSubmitted = true;
          _aiTyping = false;
          _aiMessages.add(_ChatMessage(
            text:
                '✅  Feedback submitted! Thank you for helping make WellPath better.',
            isUser: false,
          ));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiTyping = false;
          _aiMessages.add(_ChatMessage(
            text:
                'I had a hiccup saving that. Could you summarise once more so I can retry?',
            isUser: false,
          ));
        });
      }
    }
    _scrollAiToBottom();
  }

  void _scrollAiToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_aiScrollCtrl.hasClients) {
        _aiScrollCtrl.animateTo(
          _aiScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Live chat submit ───────────────────────────────────────────────────

  Future<void> _submitLiveChat() async {
    final msg = _lcMsgCtrl.text.trim();
    if (msg.isEmpty) {
      return;
    }
    setState(() => _lcSending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'timestamp': FieldValue.serverTimestamp(),
        'channel': 'live_chat_request',
        'page': widget.page,
        'type': 'support',
        'message': msg,
        'contact': _lcContactCtrl.text.trim(),
        'status': 'new',
      });
      if (mounted) {
        setState(() {
          _lcSending = false;
          _lcSent = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _lcSending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_kLiveError)));
      }
    }
  }

  // ── Anonymous submit ───────────────────────────────────────────────────

  Future<void> _submitAnonymous() async {
    final text = _anonCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _anonSending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'timestamp': FieldValue.serverTimestamp(),
        'channel': 'anonymous',
        'page': widget.page,
        'type': _anonCategory,
        'message': text,
        'status': 'new',
      });
      if (mounted) {
        setState(() {
          _anonSending = false;
          _anonSent = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _anonSending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(_kAnonError)));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Container(
          decoration: AppDecorations.modal,
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(color: AppColors.border, height: 1),
              _buildTabBar(),
              const Divider(color: AppColors.border, height: 1),
              Expanded(child: _buildContent()),
              const Divider(color: AppColors.border, height: 1),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 20),
          ),

          SizedBox(width: AppSpacing.sm + 2),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('WellPath Support', style: AppTypography.h5),
                Text('We\'re here to help',
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Gemini badge — only in AI tab when configured
          if (_mode == _ChatMode.aiAssistant && _apiKeyConfigured) ...[
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.tint10(AppColors.secondary),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border:
                    Border.all(color: AppColors.tint20(AppColors.secondary)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppColors.secondary, size: 10),
                const SizedBox(width: 3),
                Text('AI Ready',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.secondary, fontSize: 10)),
              ]),
            ),
            SizedBox(width: AppSpacing.xs + 2),
          ],

          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              icon:
                  const Icon(Icons.close, color: AppColors.textMuted, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.sm + 2),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildTab(
                mode: _ChatMode.aiAssistant,
                icon: Icons.auto_awesome_rounded,
                label: 'AI Chat'),
            _buildTab(
                mode: _ChatMode.liveChat,
                icon: Icons.headset_mic_outlined,
                label: 'Live Chat'),
            _buildTab(
                mode: _ChatMode.anonymous,
                icon: Icons.lock_outline_rounded,
                label: 'Anonymous'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required _ChatMode mode,
    required IconData icon,
    required String label,
  }) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_mode != mode) {
            setState(() => _mode = mode);
          }
          if (mode == _ChatMode.aiAssistant) {
            SchedulerBinding.instance
                .addPostFrameCallback((_) => _aiFocusNode.requestFocus());
          }
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.sm - 1),
          decoration: BoxDecoration(
            gradient: isActive ? AppGradients.button : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill - 4),
            boxShadow: isActive ? AppShadows.buttonGlow : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: isActive ? AppColors.onPrimary : AppColors.textMuted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.badge.copyWith(
                    fontSize: 11,
                    letterSpacing: 0,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.onPrimary : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Content switcher ──────────────────────────────────────────────────────

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      child: switch (_mode) {
        _ChatMode.aiAssistant => _buildAiContent(),
        _ChatMode.liveChat => _buildLiveChatContent(),
        _ChatMode.anonymous => _buildAnonContent(),
      },
    );
  }

  // ── AI content ────────────────────────────────────────────────────────────

  Widget _buildAiContent() {
    final itemCount = _aiMessages.length + (_aiTyping ? 1 : 0);
    return ListView.builder(
      key: const ValueKey(_ChatMode.aiAssistant),
      controller: _aiScrollCtrl,
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _aiMessages.length && _aiTyping) {
          return _buildTypingBubble();
        }
        return _buildMessageBubble(_aiMessages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    const double avatarW = 28.0;
    const double avatarMg = 6.0;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser)
            Container(
              width: avatarW,
              height: avatarW,
              margin: const EdgeInsets.only(right: avatarMg, bottom: 2),
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2, vertical: AppSpacing.sm + 1),
              decoration: BoxDecoration(
                gradient: msg.isUser ? AppGradients.button : null,
                color: msg.isUser ? null : AppColors.surfaceMid,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(msg.isUser ? 14 : 3),
                  bottomRight: Radius.circular(msg.isUser ? 3 : 14),
                ),
                border: msg.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                msg.text,
                style: AppTypography.body.copyWith(
                  color:
                      msg.isUser ? AppColors.onPrimary : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (msg.isUser) const SizedBox(width: avatarW + avatarMg),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 6, bottom: 2),
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2, vertical: AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMid,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(3),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Live chat content ─────────────────────────────────────────────────────

  Widget _buildLiveChatContent() {
    return SingleChildScrollView(
      key: const ValueKey(_ChatMode.liveChat),
      padding: EdgeInsets.all(AppSpacing.md),
      child: _lcSent
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 48),
                    SizedBox(height: AppSpacing.md),
                    Text(_kLiveSuccess,
                        style: AppTypography.body, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tint10(AppColors.secondary),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.tint20(AppColors.secondary)),
                    ),
                    child: Icon(Icons.headset_mic_outlined,
                        color: AppColors.secondary, size: 20),
                  ),
                  SizedBox(width: AppSpacing.sm + 2),
                  Expanded(child: Text(_kLiveTitle, style: AppTypography.h5)),
                ]),
                SizedBox(height: AppSpacing.sm + 2),
                Text(_kLiveDescription,
                    style: AppTypography.bodySmall.copyWith(height: 1.55)),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _lcContactCtrl,
                  maxLines: 1,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: _kLiveContactHint,
                    hintStyle:
                        AppTypography.input.copyWith(color: AppColors.textHint),
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: AppColors.textMuted, size: 18),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.inputBR,
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.inputBR,
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.inputBR,
                        borderSide: BorderSide(
                            color: AppColors.borderFocused, width: 1.5)),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Anonymous content ─────────────────────────────────────────────────────

  Widget _buildAnonContent() {
    return SingleChildScrollView(
      key: const ValueKey(_ChatMode.anonymous),
      padding: EdgeInsets.all(AppSpacing.md),
      child: _anonSent
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 48),
                    SizedBox(height: AppSpacing.md),
                    Text(_kAnonSuccess,
                        style: AppTypography.body, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tint10(AppColors.primary),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.tint20(AppColors.primary)),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  SizedBox(width: AppSpacing.sm + 2),
                  Expanded(child: Text(_kAnonTitle, style: AppTypography.h5)),
                ]),
                SizedBox(height: AppSpacing.sm + 2),
                Text(_kAnonDescription,
                    style: AppTypography.bodySmall.copyWith(height: 1.55)),
                SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _kCategories.map((cat) {
                    final selected = _anonCategory == cat.value;
                    return GestureDetector(
                      onTap: () => setState(() => _anonCategory = cat.value),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md - 2,
                            vertical: AppSpacing.sm - 1),
                        decoration: BoxDecoration(
                          gradient: selected ? AppGradients.button : null,
                          color: selected ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : AppColors.border,
                          ),
                          boxShadow: selected ? AppShadows.buttonGlow : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(cat.icon,
                              size: 13,
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text(cat.label,
                              style: AppTypography.badge.copyWith(
                                fontSize: 11,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.onPrimary
                                    : AppColors.textMuted,
                              )),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  // ── Input area ────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return switch (_mode) {
      _ChatMode.aiAssistant => _buildAiInput(),
      _ChatMode.liveChat => _buildLiveChatInput(),
      _ChatMode.anonymous => _buildAnonInput(),
    };
  }

  Widget _buildAiInput() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _aiInputCtrl,
              focusNode: _aiFocusNode,
              enabled: !_aiSubmitted,
              maxLines: 1,
              style: AppTypography.body,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendAiMessage(),
              decoration: InputDecoration(
                hintText: _aiSubmitted ? _kAiInputHintDone : _kAiInputHint,
                hintStyle:
                    AppTypography.input.copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                border: OutlineInputBorder(
                    borderRadius: AppRadius.pillBR,
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.pillBR,
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.pillBR,
                    borderSide:
                        BorderSide(color: AppColors.borderFocused, width: 1.5)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.pillBR,
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          _sendIconButton(
            onPressed: (_aiSubmitted || _aiTyping) ? null : _sendAiMessage,
            loading: _aiTyping,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatInput() {
    if (_lcSent) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _lcMsgCtrl,
              maxLines: 3,
              minLines: 1,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: _kLiveMsgHint,
                hintStyle:
                    AppTypography.input.copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                border: OutlineInputBorder(
                    borderRadius: AppRadius.inputBR,
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputBR,
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputBR,
                    borderSide:
                        BorderSide(color: AppColors.borderFocused, width: 1.5)),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          _sendIconButton(
            onPressed: _lcSending ? null : _submitLiveChat,
            loading: _lcSending,
          ),
        ],
      ),
    );
  }

  Widget _buildAnonInput() {
    if (_anonSent) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _anonCtrl,
              maxLines: 3,
              minLines: 1,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: _kAnonHint,
                hintStyle:
                    AppTypography.input.copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                border: OutlineInputBorder(
                    borderRadius: AppRadius.inputBR,
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputBR,
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.inputBR,
                    borderSide:
                        BorderSide(color: AppColors.borderFocused, width: 1.5)),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          _sendIconButton(
            onPressed: _anonSending ? null : _submitAnonymous,
            loading: _anonSending,
          ),
        ],
      ),
    );
  }

  // Shared gradient send icon button
  Widget _sendIconButton({
    VoidCallback? onPressed,
    bool loading = false,
    IconData icon = Icons.send_rounded,
  }) {
    final disabled = onPressed == null;
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: disabled
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(kFabSize / 2),
              border: Border.all(color: AppColors.border),
            )
          : BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(kFabSize / 2),
              boxShadow: AppShadows.buttonGlow,
            ),
      child: IconButton(
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                icon,
                size: 20,
                color: disabled ? AppColors.textMuted : AppColors.onPrimary,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypingDots — animated 3-dot typing indicator
// ─────────────────────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final raw = (_ctrl.value - i * 0.33) % 1.0;
          final phase = raw < 0 ? raw + 1.0 : raw;
          final pulse = math.sin(phase * math.pi).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 8,
            height: 8,
            transform: Matrix4.diagonal3Values(
                0.6 + 0.4 * pulse, 0.6 + 0.4 * pulse, 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.35 + 0.65 * pulse),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
