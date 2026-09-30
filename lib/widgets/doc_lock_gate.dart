import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/doc_lock.dart';
import '../theme/app_theme.dart';

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
    super.dispose();
  }

  /// Reads both again each time, so adding a screen lock in the phone's
  /// settings takes effect without restarting the app.
  Future<void> _check() async {
    final available = await widget.auth.available();
    final enabled = await DocLock.enabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
      _ready = true;
    });
  }

  // The PIN screen on older phones sends the app to the background too;
  // coming back from the prompt must not count as time away.
  void _left() {
    if (!_busy) _session.left();
  }

  void _returned() {
    if (_busy) return;
    setState(_session.returned);
  }

  /// Called when the Documents tab is opened: asks straight away if locked.
  Future<void> shown() async {
    await _check();
    if (!mounted || _open) return;
    await unlock();
  }

  Future<UnlockResult?> _ask(String reason) async {
    if (_busy) return null;
    setState(() => _busy = true);
    final result = await widget.auth.unlock(reason);
    if (mounted) setState(() => _busy = false);
    return result;
  }

  Future<void> unlock() async {
    final result = await _ask('Unlock My documents');
    if (!mounted || result == null) return;
    switch (result) {
      case UnlockResult.unlocked:
        setState(_session.unlock);
      case UnlockResult.cancelled:
        break;
      case UnlockResult.lockedOut:
        _say('Too many tries. Wait a moment and try again.');
      case UnlockResult.unavailable:
        setState(_session.unlock);
        _say("Couldn't use your phone's lock, so My documents is open.");
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
    setState(() {
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
    if (_ready && _open) return widget.builder(context, this);
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
            const Text(
              'Use your fingerprint or phone PIN to see your forms, '
              'certificates and ID proofs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
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
