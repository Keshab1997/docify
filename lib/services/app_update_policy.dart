/// Pure decision logic for Google Play in-app updates.
///
/// No Flutter, no platform channels: the rules stay unit-testable (see
/// `test/app_update_policy_test.dart`). The plugin's own model is mapped
/// into [UpdateInfo] by `app_update_mobile.dart`, so nothing in this file
/// knows which package provides the data.
library;

/// What the app should offer for the update situation it found.
enum UpdateDecision {
  /// Nothing to offer: no update, or Play would not allow either flow.
  none,

  /// Download in the background while the user keeps working.
  flexible,

  /// Full-screen flow run by Google Play — reserved for urgent releases.
  immediate,
}

/// How a request to start an update ended.
enum UpdateStartResult {
  /// Play accepted it and the flow is running.
  started,

  /// The user declined inside Play's own UI. A "Not now" in *our* dialog
  /// never reaches this — it is handled before the call.
  denied,

  /// Play refused or threw; the user can still update from the store.
  failed,

  /// This platform has no in-app updates at all (the web build).
  unavailable,
}

/// What the platform knows about the update situation, reduced to the fields
/// a decision needs.
class UpdateInfo {
  const UpdateInfo({
    required this.available,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    required this.priority,
    this.stalenessDays,
    this.versionCode,
    this.downloaded = false,
  });

  /// A newer version is on Play and this install is older.
  final bool available;

  /// Play permits the flexible (background) flow.
  final bool flexibleAllowed;

  /// Play permits the immediate (blocking) flow.
  final bool immediateAllowed;

  /// `updatePriority` set in the Play Console, 0–5.
  final int priority;

  /// Days since the device learned about this update; null when Play does
  /// not know yet (fresh install, no pass through the store).
  final int? stalenessDays;

  /// Version code of the available update; null when unknown.
  final int? versionCode;

  /// A flexible download already finished — only a restart is left.
  final bool downloaded;
}

/// Picks the flow to offer, following Google's urgency guidance: priority
/// first, then how long the update has been sitting uninstalled.
///
/// * priority 4–5 releases, and priority 3 ones ignored for a week, get the
///   immediate flow — but only when Play allows it;
/// * everything else gets the flexible flow;
/// * when neither flow is allowed, nothing is offered: a blocking prompt
///   Play would reject helps no one.
UpdateDecision decideUpdate(UpdateInfo? info) {
  if (info == null || !info.available) return UpdateDecision.none;
  final urgent = info.priority >= 4 ||
      (info.priority >= 3 && (info.stalenessDays ?? -1) >= 7);
  if (urgent && info.immediateAllowed) return UpdateDecision.immediate;
  if (info.flexibleAllowed) return UpdateDecision.flexible;
  return UpdateDecision.none;
}
