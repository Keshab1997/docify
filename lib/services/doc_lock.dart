import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What happened when the phone was asked to confirm it's the owner.
enum UnlockResult {
  /// Fingerprint, face, PIN, pattern or password matched.
  unlocked,

  /// The prompt was closed or timed out; stay locked without a fuss.
  cancelled,

  /// Too many wrong tries, so the phone refuses new ones for a while.
  lockedOut,

  /// This phone can't run the check: no screen lock, or a device error.
  unavailable,
}

/// The phone's own screen lock, behind a seam so tests can stand in for it.
abstract class DeviceAuth {
  /// Whether the phone has a screen lock or enrolled biometrics to ask for.
  Future<bool> available();

  /// Shows the system fingerprint/PIN prompt with [reason] in it.
  Future<UnlockResult> unlock(String reason);
}

/// [DeviceAuth] through local_auth. Android does the checking; Docify never
/// sees a fingerprint or a PIN, only whether they matched.
class PhoneAuth implements DeviceAuth {
  const PhoneAuth();

  @override
  Future<bool> available() async {
    // A browser has no phone lock to ask, so the web preview stays open.
    if (kIsWeb) return false;
    // A transient platform error is not proof that the phone has no lock;
    // the gate catches it and stays closed instead of silently disabling it.
    return LocalAuthentication().isDeviceSupported();
  }

  @override
  Future<UnlockResult> unlock(String reason) async {
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: reason,
        // Older phones show the PIN screen as a separate activity; keep the
        // prompt alive instead of failing when the app goes behind it.
        persistAcrossBackgrounding: true,
      );
      return ok ? UnlockResult.unlocked : UnlockResult.cancelled;
    } on LocalAuthException catch (e) {
      return unlockResultFor(e.code);
    } catch (_) {
      return UnlockResult.unavailable;
    }
  }
}

/// Sorts local_auth's failures into what My documents does next.
@visibleForTesting
UnlockResult unlockResultFor(LocalAuthExceptionCode code) {
  switch (code) {
    case LocalAuthExceptionCode.userCanceled:
    case LocalAuthExceptionCode.systemCanceled:
    case LocalAuthExceptionCode.timeout:
    case LocalAuthExceptionCode.authInProgress:
    case LocalAuthExceptionCode.userRequestedFallback:
      return UnlockResult.cancelled;
    case LocalAuthExceptionCode.temporaryLockout:
    case LocalAuthExceptionCode.biometricLockout:
      return UnlockResult.lockedOut;
    default:
      // No screen lock any more, no screen to show the prompt on, or a
      // device fault. None of these is a wrong guess, and staying shut
      // would lock the owner out of their own files for good.
      return UnlockResult.unavailable;
  }
}

/// The owner's choice to lock My documents, saved on the phone.
class DocLock {
  DocLock._();

  static const _key = 'doc_lock';

  /// On unless the owner turned it off. A phone without a screen lock
  /// still stays open; see [DeviceAuth.available].
  static Future<bool> enabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
  }
}

/// Whether My documents is unlocked right now.
///
/// Unlocking lasts while the app is in use. Short trips out of it (the file
/// picker, the camera, a share sheet) keep it open; being away longer than
/// [grace] locks it again.
class LockSession {
  LockSession({
    this.grace = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration grace;
  final DateTime Function() _now;

  bool _unlocked = false;
  DateTime? _leftAt;

  bool get unlocked => _unlocked;

  void lock() {
    _unlocked = false;
    _leftAt = null;
  }

  void unlock() {
    _unlocked = true;
    _leftAt = null;
  }

  /// The app went into the background.
  void left() {
    _leftAt ??= _now();
  }

  /// The app is in front again.
  void returned() {
    final leftAt = _leftAt;
    _leftAt = null;
    if (leftAt != null && _now().difference(leftAt) >= grace) {
      _unlocked = false;
    }
  }
}
