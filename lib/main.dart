// lib/main.dart
import 'package:flutter/material.dart';
import 'landing_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root of application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WellPath | Welcome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: Typography.whiteMountainView, // readable on dark gradient
      ),
      home: const LandingPage(),
    );
  }
}