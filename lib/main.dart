import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BundleLensApp());
}

class BundleLensApp extends StatelessWidget {
  const BundleLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BundleLens',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
