import 'package:in_app_update/in_app_update.dart';

import 'app_update_policy.dart';

/// Asks Google Play whether a newer Docify exists, and drives the update
/// flow that follows.
///
/// Android side only in practice: the Play API answers for builds installed
/// from the Play Store, and nothing else. A sideloaded APK, a debug build or
/// the web build fails the channel call, so every entry point here degrades
/// to "nothing to do" instead of throwing — callers can use it on any
/// platform without branching.
class AppUpdate {
  const AppUpdate._();

  /// What Play knows right now, or null when it could not be asked.
  static Future<UpdateInfo?> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return UpdateInfo(
        available:
            info.updateAvailability == UpdateAvailability.updateAvailable,
        flexibleAllowed: info.flexibleUpdateAllowed,
        immediateAllowed: info.immediateUpdateAllowed,
        priority: info.updatePriority,
        stalenessDays: info.clientVersionStalenessDays,
        versionCode: info.availableVersionCode,
        downloaded: info.installStatus == InstallStatus.downloaded,
      );
    } catch (_) {
      // Not installed from Play, no Play at all, or the web build. Not
      // fatal: there is simply no update to offer.
      return null;
    }
  }

  /// Starts the background download. Needs a completed [check] first.
  static Future<UpdateStartResult> startFlexible() async {
    try {
      return _map(await InAppUpdate.startFlexibleUpdate());
    } catch (_) {
      return UpdateStartResult.failed;
    }
  }

  /// Hands over to Play's full-screen UI. Needs a completed [check] first.
  static Future<UpdateStartResult> startImmediate() async {
    try {
      return _map(await InAppUpdate.performImmediateUpdate());
    } catch (_) {
      return UpdateStartResult.failed;
    }
  }

  /// Installs the downloaded update; Play restarts the app when it goes
  /// through. False means nothing was ready or Play refused.
  static Future<bool> completeFlexible() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (_) {
      // The download survives a failed call; the next resume check finds
      // the same install state again.
      return false;
    }
  }

  /// Emits true once a flexible download is finished and only the restart is
  /// left. Errors end the wait quietly — the resume check would see the same
  /// state on the next foreground anyway.
  static Stream<bool> readyToInstall() => InAppUpdate.installUpdateListener.map(
        (status) => status == InstallStatus.downloaded,
      );

  static UpdateStartResult _map(AppUpdateResult result) {
    switch (result) {
      case AppUpdateResult.success:
        return UpdateStartResult.started;
      case AppUpdateResult.userDeniedUpdate:
        return UpdateStartResult.denied;
      case AppUpdateResult.inAppUpdateFailed:
        return UpdateStartResult.failed;
    }
  }
}
