import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/ads.dart';
import 'theme/app_theme.dart';
import 'screens/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize AdMob (no-op on web). Real unit ids arrive as dart-defines -
  // see services/ads_mobile.dart.
  await Ads.initialize();
  runApp(const ProviderScope(child: DocifyApp()));
}

class DocifyApp extends StatelessWidget {
  const DocifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Docify - Photo, PDF & CV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavScreen(),
    );
  }
}
