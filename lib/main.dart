import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_info.dart';
import 'screens/main_nav_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ads.dart';
import 'services/app_auth.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase + Google Sign-in setup. Never fatal: without
  // android/app/google-services.json the app is a guest app.
  await AppAuth.bootstrap();
  await Ads.initialize();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('onboarding_seen_v1') ?? false;
  runApp(ProviderScope(child: DocifyApp(showOnboarding: !hasSeenOnboarding)));
}

class DocifyApp extends StatelessWidget {
  final bool showOnboarding;

  const DocifyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showOnboarding ? const OnboardingScreen() : const MainNavScreen(),
    );
  }
}
