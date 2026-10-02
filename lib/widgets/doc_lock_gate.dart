import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/doc_lock.dart';
import '../theme/app_theme.dart';
import 'doc_guard_scope.dart';

/// Keeps My documents behind the phone's fingerprint, face or screen lock.
///
/// It asks when the tab is opened ([DocLockGateState.shown]) and again after
/// the app has been away for a while (see [LockSession]). Phones without a
/// screen lock have nothing to ask for and stay open, as does the web.
class DocLockGate extends StatefulWidget {
  const DocLockGate({
    super.key,
    required this.builder,
    this.auth = const PhoneAuth(),
  });

  /// Builds the documents page; only called while unlocked, so nothing of
  /// the files is on screen behind the lock.
  final Widget Function(BuildContext context, DocLockGateState gate) builder;

  final DeviceAuth auth;

  @override
  State<DocLockGate> createState() => DocLockGateState();
}

class DocLockGateState extends State<DocLockGate> {
  final _session = LockSession();
  final _changes = ValueNotifier<int>(0);
  bool _obscured = false;
  String? _authProblem;
  late final AppLifecycleListener _lifecycle;

  /// False until the phone and the setting are checked, so the files never
  /// flash up before the lock does.
  bool _ready = false;
  bool _available = false;
  bool _enabled = true;
  bool _busy = false;

  /// Whether the lock is switched on and this phone can use it.
  bool get lockOn => _available && _enabled;

  bool get _open => !lockOn || _session.unlocked;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _left, onShow: _returned);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _changes.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    if (!mounted) return;
    setState(change);
    _changes.value++;
  }

  /// Preview routes share this session rather than asking a second time.
  /// The guard covers them while backgrounded and after the session expires.
  Widget guard(Widget child) {
    return AnimatedBuilder(
      animation: _changes,
      child: DocGuardScope(guard: guard, child: child),
      builder: (context, page) {
        final visible = _ready && _open && !_obscured;
        return Stack(fit: StackFit.expand, children: [
          // Offstage preserves a tool's state through a picker/share-sheet trip
          // but paints no private pixels or semantics behind the lock overlay.
          Offstage(offstage: !visible, child: page!),
          if (!visible) Scaffold(
            appBar: AppBar(title: const Text('My documents')),
            body: _ready ? _locked() : const Center(child: CircularProgressIndicator()),
          ),
        ]);
      },
    );
  }

  void lockNow() {
    if (lockOn) _update(_session.lock);
  }

  /// Reads both again each time, so adding a screen lock in the phone's
  /// settings takes effect without restarting the app.
  Future<void> _check() async {
    final enabled = await DocLock.enabled();
    try {
      final available = await widget.auth.available();
      _update(() {
        _available = available;
        _enabled = enabled;
        _ready = true;
        _authProblem = null;
      });
    } catch (_) {
      _update(() {
        _available = !kIsWeb;
        _enabled = enabled;
        _ready = true;
        _authProblem = 'Could not check the phone lock. Please try again.';
      });
    }
  }

  // The PIN screen on older phones sends the app to the background too;
  // coming back from the prompt must not count as time away.
  void _left() {
    if (!_busy) {
      _update(() {
        _session.left();
        _obscured = true;
      });
    }
  }

  void _returned() {
    if (_busy) return;
    _update(() {
      _session.returned();
      _obscured = false;
    });
  }

  /// Called when the Documents tab is opened: asks straight away if locked.
  Future<void> shown() async {
    await _check();
    if (!mounted || _open) return;
    await unlock();
  }

  Future<UnlockResult?> _ask(String reason) async {
    if (_busy) return null;
    _update(() => _busy = true);
    final result = await widget.auth.unlock(reason);
    if (mounted) _update(() => _busy = false);
    return result;
  }

  Future<void> unlock() async {
    final result = await _ask('Unlock My documents');
    if (!mounted || result == null) return;
    switch (result) {
      case UnlockResult.unlocked:
        _update(_session.unlock);
      case UnlockResult.cancelled:
        break;
      case UnlockResult.lockedOut:
        _say('Too many tries. Wait a moment and try again.');
      case UnlockResult.unavailable:
        _update(() => _authProblem = 'Phone lock is unavailable. Try again or '
            'choose the phone PIN option in the system prompt.');
        _say('Could not verify the phone lock. Your documents remain locked.');
    }
  }

  /// Turns the lock on or off. The phone confirms it's the owner first, so
  /// someone else holding it can't simply switch the lock off.
  Future<void> toggle() async {
    if (kIsWeb) {
      _say('The lock works in the Android app.');
      return;
    }
    await _check();
    if (!mounted) return;
    if (!_available) {
      _say('Set a screen lock (PIN, pattern or fingerprint) in your phone '
          'settings to lock My documents.');
      return;
    }
    final turnOn = !_enabled;
    final result = await _ask(
      turnOn ? 'Lock My documents' : 'Turn off the lock on My documents',
    );
    if (!mounted || result == null) return;
    if (result == UnlockResult.lockedOut) {
      _say('Too many tries. Wait a moment and try again.');
    }
    if (result != UnlockResult.unlocked) return;
    await DocLock.setEnabled(turnOn);
    if (!mounted) return;
    _update(() {
      _enabled = turnOn;
      _session.unlock();
    });
    _say(
      turnOn
          ? 'My documents will ask for your fingerprint or PIN'
          : 'Lock turned off',
    );
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _open && !_obscured) {
      return DocGuardScope(guard: guard, child: widget.builder(context, this));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: _ready ? _locked() : null,
    );
  }

  Widget _locked() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 64,
              color: AppColors.primaryButton,
            ),
            const SizedBox(height: Space.lg),
            const Text(
              'My documents is locked',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Space.sm),
            Text(
              _authProblem ??
                  'Use your fingerprint or phone PIN to see your forms, '
                      'certificates and ID proofs.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: Space.xl),
            FilledButton.icon(
              onPressed: _busy ? null : unlock,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
