// lib/main.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Integrated Mapbox initialization (access token setup)
//   • Added Web-safe guard for Mapbox (prevents crash on Flutter Web)
//   • Preserved Firebase initialization
//   • Maintained Riverpod ProviderScope
//   • Retained AppTheme (dark-first design)
//   • Connected Discover providers (Mapbox dependency)
//   • Cleaned and unified app bootstrap flow — Sconl Peter
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ← IMPORTANT (kIsWeb)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/style/app_theme.dart';

// TODO: Move this to secure storage (env/secrets)
const String kMapboxAccessToken = 'YOUR_MAPBOX_ACCESS_TOKEN';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────────────────────────────────
  // Initialize Firebase
  // ───────────────────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Initialize Mapbox (ONLY for mobile platforms)
  // ───────────────────────────────────────────────────────────────────────────
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(kMapboxAccessToken);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Launch App with Riverpod
  // ───────────────────────────────────────────────────────────────────────────
  runApp(const ProviderScope(child: WellPathApp()));
}

class WellPathApp extends ConsumerWidget {
  const WellPathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'WellPath',
      debugShowCheckedModeBanner: false,

      // ───────────────────────────────────────────────────────────────────────
      // Theme Configuration (Dark-first brand identity)
      // ───────────────────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,

      // ───────────────────────────────────────────────────────────────────────
      // Navigation (GoRouter / AppRouter)
      // ───────────────────────────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}
