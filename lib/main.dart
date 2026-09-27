import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/ads.dart';
import 'theme/app_theme.dart';
import 'screens/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize AdMob with test IDs in debug, real in release (no-op on web)
  await Ads.initialize();
  runApp(const ProviderScope(child: JobDocApp()));
}

class JobDocApp extends StatelessWidget {
  const JobDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobDoc - Photo, PDF & CV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavScreen(),
    );
  }
}
