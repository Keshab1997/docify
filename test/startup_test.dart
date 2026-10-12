import 'dart:async';

import 'package:docify/main.dart';
import 'package:docify/screens/main_nav_screen.dart';
import 'package:docify/screens/onboarding_screen.dart';
import 'package:docify/services/app_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('first frame is drawable while local preferences are pending', (
    tester,
  ) async {
    final preferences = Completer<bool>();
    final services = Completer<void>();
    var servicesStarted = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingSeenProvider.overrideWith((ref) => preferences.future),
          backgroundStartupProvider.overrideWith((ref) {
            servicesStarted = true;
            return services.future;
          }),
        ],
        child: const DocifyApp(),
      ),
    );

    expect(find.text('Docify'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(MainNavScreen), findsNothing);
    // The post-frame callback ran even though neither future completed.
    expect(servicesStarted, isTrue);
    expect(preferences.isCompleted, isFalse);
    expect(services.isCompleted, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('returning guest opens Home without waiting for optional SDKs', (
    tester,
  ) async {
    final preferences = Completer<bool>();
    final services = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingSeenProvider.overrideWith((ref) => preferences.future),
          backgroundStartupProvider.overrideWith((ref) => services.future),
        ],
        child: const DocifyApp(),
      ),
    );
    preferences.complete(true);
    await tester.pump();
    await tester.pump();

    // No minimum splash/animation duration, even if a service never responds.
    expect(find.byType(MainNavScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(services.isCompleted, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('first install still opens onboarding with SDKs pending', (
    tester,
  ) async {
    final services = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingSeenProvider.overrideWith((ref) async => false),
          backgroundStartupProvider.overrideWith((ref) => services.future),
        ],
        child: const DocifyApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MainNavScreen), findsNothing);
    expect(services.isCompleted, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a preferences failure cannot trap the app on splash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingSeenProvider.overrideWith(
            (ref) async => throw StateError('Preferences unavailable'),
          ),
          backgroundStartupProvider.overrideWith((ref) async {}),
        ],
        child: const DocifyApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MainNavScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('optional SDK failure does not replace a working Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingSeenProvider.overrideWith((ref) async => true),
          backgroundStartupProvider.overrideWith(
            (ref) async => throw StateError('Optional SDK unavailable'),
          ),
        ],
        child: const DocifyApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MainNavScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainNavScreen)),
    );
    expect(container.read(backgroundStartupProvider).hasError, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('missing onboarding preference means first installation', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(onboardingSeenProvider.future), isFalse);
  });

  test('saved onboarding preference is respected', () async {
    SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(onboardingSeenProvider.future), isTrue);
  });
}
