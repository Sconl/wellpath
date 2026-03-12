// lib/main.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHANGELOG
// ─────────────────────────────────────────────────────────────────────────────
//   • Replaced inline ThemeData with AppTheme.dark / AppTheme.light — Sconl Peter
//   • Added themeMode: ThemeMode.dark as the WellPath default
//   • Cleaned up app title string
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

      // Dark is the WellPath default — the whole brand is built around it.
      // ThemeMode.system will respect the user's OS preference if you ever
      // want to offer that toggle in settings.
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  ThemeMode.dark,

      routerConfig: router,
    );
  }
}