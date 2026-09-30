import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_auth.dart';
import 'drive_api.dart';
import 'drive_sync.dart';

/// Opt-in automatic Drive backup.
///
/// When the user switches on "Automatic backup" in the sync sheet, Docify
/// silently runs the normal [DriveSync] reconcile when the app opens and
/// when it returns to the foreground. Strictly silent by design:
///
///  * it only runs when the user is already signed in AND has already
///    granted Drive access — otherwise it does nothing;
///  * it never prompts, never shows UI and never throws;
///  * errors are swallowed (best-effort), the manual sheet always works;
///  * the same overwrite-free, delete-free rules as manual sync apply.
///
/// A minimum gap between runs keeps resume-flapping free of network churn.
class AutoSync {
  AutoSync._();

  static const String _enabledKey = 'auto_sync_enabled';
  static const String _lastRunKey = 'auto_sync_last_ms';

  /// Minimum gap between silent runs.
  static const Duration minInterval = Duration(minutes: 15);

  /// Never run two silent syncs at once.
  static bool _running = false;

  /// Whether the user has opted in to automatic backup.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Persists the opt-in choice (the sync sheet switch calls this).
  static Future<void> setEnabled(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, on);
  }

  /// Epoch millis of the last successful silent run (null = never).
  static Future<int?> lastRunMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastRunKey);
  }

  /// One silent attempt. Safe to call from anywhere at any time.
  /// Returns true when a run completed (even when it moved 0 files).
  static Future<bool> maybeRun() async {
    if (_running) return false;
    try {
      if (!await isEnabled()) return false;
      // Guest or signed-out: nothing to sync against.
      if (!AppAuth.firebaseReady || AppAuth.user == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_lastRunKey);
      if (last != null &&
          DateTime.now().millisecondsSinceEpoch - last <
              minInterval.inMilliseconds) {
        return false; // Too soon — skip quietly.
      }

      // Silent token only: null means Drive was never granted on this
      // device, and an automatic run must never trigger the consent UI.
      final token = await AppAuth.driveTokenIfGranted();
      if (token == null) return false;

      _running = true;
      try {
        final api = DriveApi(token);
        final plan = await DriveSync.plan(api);
        if (!plan.isEmpty) {
          await DriveSync.run(api, plan, onProgress: (_, __, ___) {});
        }
        await prefs.setInt(
          _lastRunKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return true;
      } finally {
        _running = false;
      }
    } catch (e) {
      // Best-effort by contract: log and move on.
      debugPrint('AutoSync: silent run skipped ($e)');
      return false;
    }
  }
}
