import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_info.dart';
import 'screens/main_nav_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_startup.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw immediately. Optional SDKs must never hold Android's native splash
  // hostage; the launch gate starts them only after Flutter's first frame.
  runApp(const ProviderScope(child: DocifyApp()));
}

class DocifyApp extends StatelessWidget {
  /// An explicit route is useful for previews/tests. Normal launches read the
  /// saved onboarding flag without delaying runApp or waiting for any SDK.
  final bool? showOnboarding;

  const DocifyApp({super.key, this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showOnboarding == null
          ? const _LaunchGate()
          : showOnboarding!
              ? const OnboardingScreen()
              : const MainNavScreen(),
    );
  }
}

class _LaunchGate extends ConsumerStatefulWidget {
  const _LaunchGate();

  @override
  ConsumerState<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<_LaunchGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backgroundStartupProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingSeenProvider);
    return onboarding.when(
      data: (seen) => seen ? const MainNavScreen() : const OnboardingScreen(),
      // A local preferences failure is not a reason to trap a guest on splash.
      error: (_, __) => const MainNavScreen(),
      loading: () => const _LaunchPlaceholder(),
    );
  }
}

class _LaunchPlaceholder extends StatelessWidget {
  const _LaunchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAF2FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_rounded,
                size: 80, color: AppColors.titleBlue),
            SizedBox(height: 16),
            Text(kAppShortName, style: AppText.display),
          ],
        ),
      ),
    );
  }
}
