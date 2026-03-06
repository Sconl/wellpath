// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'landing_page.dart';
import 'features/auth/presentation/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// define router at top-level
final GoRouter _router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // add more routes here (signup, home, profile, etc)
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root of application
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wellpath | Wellcome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: Typography.whiteMountainView, // readable on dark gradient
      ),
      routerConfig: _router,
    );
  }
}