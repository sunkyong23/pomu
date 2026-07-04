import 'package:flutter/material.dart';

import 'core/theme/pomu_theme.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const PomuApp());
}

class PomuApp extends StatelessWidget {
  const PomuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomu',
      debugShowCheckedModeBanner: false,
      theme: PomuTheme.light(),
      home: const SplashScreen(),
    );
  }
}
