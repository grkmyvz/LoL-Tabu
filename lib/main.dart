import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LoLTabuApp());
}

class LoLTabuApp extends StatelessWidget {
  const LoLTabuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoL Tabu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const HomeScreen(),
    );
  }
}
