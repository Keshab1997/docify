import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_update.dart';
import '../services/app_update_policy.dart';
import '../theme/app_theme.dart';

/// Looks for a newer version on Google Play and, when there is one worth
/// offering, walks the user through it.
///
/// Called a few seconds after launch and on every return to the foreground —
/// never from `main()`, so the first frame never waits on Play. Everything
/// here is best-effort: no update, no Play, or a flow Play refuses all end in
/// silence rather than an error.
///
/// [onResume] narrows the check to downloads that already finished: the
/// availability prompt belongs to launch, while coming back to the app is
/// when a background download is most likely to be done.
Future<void> showUpdatePromptIfAny(
  BuildContext context, {
  bool onResume = false,
}) async {
  final info = await AppUpdate.check();
  if (!context.mounted || info == null) return;

  // A finished download ignores the snooze: the user already said yes to it.
  if (info.downloaded) {
    await _showRestartDialog(context);
    return;
  }
  if (onResume) return;

  final decision = decideUpdate(info);
  if (decision == UpdateDecision.none) return;
  if (decision == UpdateDecision.flexible && await _snoozed()) return;
  if (!context.mounted) return;

  if (decision == UpdateDecision.immediate) {
    await _showImmediateDialog(context);
  } else {
    await _showFlexibleDialog(context);
  }
}

/// "Not now" buys 24 hours of quiet: long enough not to nag, short enough
/// that an ignored update gets another chance tomorrow.
const String _snoozeKey = 'update_prompt_snoozed_until_v1';
const Duration _snoozeFor = Duration(hours: 24);

/// The restart prompt shows at most once per app run — a user who taps
/// "Later" should not meet the same dialog again on every resume.
bool _restartPrompted = false;

/// Live watch for a flexible download finishing while the app keeps running;
/// without it the user would only hear about it on the next launch.
StreamSubscription<bool>? _watch;

Future<bool> _snoozed() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_snoozeKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  } catch (_) {
    // A failed read must never hide the prompt.
    return false;
  }
}

Future<void> _snooze() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _snoozeKey,
      DateTime.now().add(_snoozeFor).millisecondsSinceEpoch,
    );
  } catch (_) {
    // Failing to remember the answer only means the prompt returns sooner.
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// One shape for every prompt in this file: icon, title, message, a quiet
/// way out and a single primary action.
Future<bool> _ask(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String cancel,
  required String confirm,
}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sheet),
      ),
      icon: Icon(icon, color: AppColors.primaryButton, size: 32),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return answer ?? false;
}

Future<void> _showFlexibleDialog(BuildContext context) async {
  final go = await _ask(
    context,
    icon: Icons.system_update_alt_rounded,
    title: 'Update available',
    message: 'A newer version of Docify is on Google Play. It downloads in '
        'the background — keep using the app, then restart when it is ready.',
    cancel: 'Not now',
    confirm: 'Update',
  );
  if (!context.mounted) return;
  if (!go) {
    await _snooze();
    return;
  }

  final result = await AppUpdate.startFlexible();
  if (!context.mounted) return;
  if (result == UpdateStartResult.started) {
    _snack(context, 'Downloading the update in the background.');
    _watchForReady(context);
  } else if (result == UpdateStartResult.failed ||
      result == UpdateStartResult.unavailable) {
    _snack(
      context,
      'Could not start the update. You can update from the Play Store '
      'instead.',
    );
  }
}

Future<void> _showImmediateDialog(BuildContext context) async {
  final go = await _ask(
    context,
    icon: Icons.error_outline_rounded,
    title: 'Important update',
    message: 'This update fixes issues that matter. Google Play will update '
        'Docify now, and the app restarts when it is done.',
    cancel: 'Not now',
    confirm: 'Update now',
  );
  if (!context.mounted) return;
  if (!go) {
    await _snooze();
    return;
  }

  final result = await AppUpdate.startImmediate();
  if (!context.mounted) return;
  if (result == UpdateStartResult.failed ||
      result == UpdateStartResult.unavailable) {
    _snack(
      context,
      'Could not start the update. You can update from the Play Store '
      'instead.',
    );
  }
  // "started" needs no feedback: Play takes over the screen itself — and a
  // "denied" means the user just said no on that same screen.
}

Future<void> _showRestartDialog(BuildContext context) async {
  if (_restartPrompted) return;
  _restartPrompted = true;

  final go = await _ask(
    context,
    icon: Icons.restart_alt_rounded,
    title: 'Update ready',
    message: 'The new version of Docify has been downloaded. Restart to '
        'finish installing it.',
    cancel: 'Later',
    confirm: 'Restart',
  );
  if (!context.mounted || !go) return;

  final done = await AppUpdate.completeFlexible();
  if (!done && context.mounted) {
    _snack(
      context,
      'Could not restart right now — the update is safe and will install on '
      'the next launch.',
    );
  }
}

/// Watches the install channel until the download lands, then offers the
/// restart wherever the user is. The navigator outlives tab switches, so the
/// prompt is not tied to the screen that started the download.
void _watchForReady(BuildContext context) {
  final navigator = Navigator.of(context);
  unawaited(_watch?.cancel());
  _watch = AppUpdate.readyToInstall().listen(
    (ready) {
      if (!ready || !navigator.mounted) return;
      unawaited(_watch?.cancel());
      _watch = null;
      unawaited(_showRestartDialog(navigator.context));
    },
    // A stream error just ends the watch quietly; the resume check finds the
    // same install state on the next foreground.
    onError: (_) {},
  );
}
