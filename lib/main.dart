import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/main_nav.dart';
import 'services/app_auth.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase + Google Sign-in setup. Never fatal: without
  // android/app/google-services.json the app is a guest app.
  await AppAuth.bootstrap();
  await Ads.initialize();
  runApp(const ProviderScope(child: DocifyApp()));
}

class DocifyApp extends StatelessWidget {
  const DocifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Docify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainNav(),
    );
  }
}
