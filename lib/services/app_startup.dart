import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads.dart';
import 'app_auth.dart';

/// Only local routing data belongs on the launch path. No network, account
/// chooser, ad response, or minimum splash duration is needed to open Docify.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_seen_v1') ?? false;
});

/// Started after the first frame and deliberately independent of routing.
/// Firebase restores its local session only; Google/Drive authorization is
/// still exclusive to an explicit user tap. Both initializers are single-flight
/// and best effort, so a slow or unavailable SDK cannot strand a guest.
final backgroundStartupProvider = FutureProvider<void>((ref) async {
  await Future.wait([AppAuth.bootstrap(), Ads.initialize()]);
});
