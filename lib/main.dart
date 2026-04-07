// lib/main.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   v3.0.0 — Unified bootstrap:
//            • Firebase initialization (single entry point)
//            • Web-safe Mapbox initialization (kIsWeb guard)
//            • NotificationService.initialize() (idempotent)
//            • SeedService.ensureSeeded() (dev-only, removable)
//            • Clean Riverpod + GoRouter integration
//            • Dark-first theme preserved
//            • Side-effects centralized (no scattered init calls)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/style/app_theme.dart';

import 'features/notifications/notification_service.dart';
import 'features/bookings/data/trainer_seed_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// TODO: Move to secure storage (env / secrets manager)
const String kMapboxAccessToken = 'YOUR_MAPBOX_ACCESS_TOKEN';

// Toggle seeding (disable in production)
const bool kEnableSeeding = true;

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────────────────────────────────
  // Firebase
  // ───────────────────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Mapbox (mobile only — prevents Flutter Web crash)
  // ───────────────────────────────────────────────────────────────────────────
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(kMapboxAccessToken);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Notifications (safe to call every launch)
  // ───────────────────────────────────────────────────────────────────────────
  await NotificationService.instance.initialize();

  // ───────────────────────────────────────────────────────────────────────────
  // Dev Seeding (REMOVE when onboarding is live)
  // ───────────────────────────────────────────────────────────────────────────
  if (kEnableSeeding) {
    await SeedService.ensureSeeded();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // App Launch
  // ───────────────────────────────────────────────────────────────────────────
  runApp(const ProviderScope(child: WellPathApp()));
}

// ─────────────────────────────────────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────────────────────────────────────

class WellPathApp extends ConsumerWidget {
  const WellPathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'WellPath',
      debugShowCheckedModeBanner: false,

      // ───────────────────────────────────────────────────────────────────────
      // Theme (Dark-first brand identity)
      // ───────────────────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // ───────────────────────────────────────────────────────────────────────
      // Navigation (GoRouter — role-aware)
      // ───────────────────────────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}