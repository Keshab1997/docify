import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/app_auth.dart';
import '../services/drive/drive_api.dart';
import '../services/drive/drive_sync.dart';
import '../theme/app_theme.dart';

/// Opens the "Sync with Google Drive" sheet and returns true when the local
/// document list may have changed (files were downloaded), so the caller
/// can reload. Runs entirely in the user's own Google account.
Future<bool> showSyncSheet(BuildContext context) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const SyncSheet(),
  );
  return changed ?? false;
}

enum _Phase {
  loading,
  needSignIn,
  needDrive,
  ready,
  running,
  inSync,
  done,
  error
}

class SyncSheet extends StatefulWidget {
  const SyncSheet({super.key});

  @override
  State<SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<SyncSheet> {
  _Phase _phase = _Phase.loading;
  DriveApi? _api;
  SyncPlan? _plan;
  SyncOutcome? _outcome;
  String _error = '';
  bool _configured = true;
  bool _busy = false; // button taps in flight
  int _done = 0;
  int _total = 0;
  String _label = '';

  @override
  void initState() {
    super.initState();
    _silentStart();
  }

  Future<void> _silentStart() async {
    if (!AppAuth.firebaseReady) {
      _setState(() {
        _configured = false;
        _phase = _Phase.needSignIn;
      });
      return;
    }
    if (AppAuth.user == null) {
      _setState(() {
        _configured = true;
        _phase = _Phase.needSignIn;
      });
      return;
    }
    try {
      final token = await AppAuth.driveTokenIfGranted();
      if (!mounted) return;
      if (token == null) {
        _setState(() => _phase = _Phase.needDrive);
        return;
      }
      await _planWith(token);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _planWith(String token) async {
    _setState(() {
      _phase = _Phase.loading;
      _api = DriveApi(token);
    });
    try {
      final plan = await DriveSync.plan(_api!);
      if (!mounted) return;
      _setState(() {
        _plan = plan;
        _phase = plan.isEmpty ? _Phase.inSync : _Phase.ready;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _signIn() async {
    if (_busy) return;
    _setState(() => _busy = true);
    try {
      await AppAuth.signIn();
      if (mounted) await _silentStart();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled && mounted) {
        _setState(() => _phase = _Phase.needSignIn);
      } else if (mounted) {
        _fail(e);
      }
    } catch (e) {
      if (mounted) _fail(e);
    } finally {
      if (mounted) _setState(() => _busy = false);
    }
  }

  Future<void> _allowDrive() async {
    if (_busy) return;
    _setState(() {
      _busy = true;
      _phase = _Phase.loading;
    });
    try {
      final token = await AppAuth.driveToken();
      if (!mounted) return;
      await _planWith(token);
    } catch (e) {
      if (mounted) _fail(e);
    } finally {
      if (mounted) _setState(() => _busy = false);
    }
  }

  Future<void> _startSync() async {
    final api = _api;
    final plan = _plan;
    if (api == null || plan == null) return;
    _setState(() {
      _phase = _Phase.running;
      _done = 0;
      _total = plan.total;
      _label = '';
    });
    try {
      final outcome = await DriveSync.run(
        api,
        plan,
        onProgress: (done, total, label) {
          if (!mounted) return;
          _setState(() {
            _done = done;
            _total = total;
            _label = label;
          });
        },
      );
      if (!mounted) return;
      _setState(() {
        _outcome = outcome;
        _phase = _Phase.done;
      });
    } catch (e) {
      _fail(e);
    }
  }

  void _retry() {
    _setState(() {
      _plan = null;
      _outcome = null;
      _phase = _Phase.loading;
    });
    _silentStart();
  }

  void _fail(Object e) {
    _setState(() {
      _error = e.toString();
      _phase = _Phase.error;
    });
  }

  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _close({bool changed = false}) {
    Navigator.of(context).pop(changed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sync with Google Drive',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your account, your Drive — files go to a Docify folder in '
            'the Google account you choose.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 18),
          ...?_body(),
        ],
      ),
    );
  }

  List<Widget>? _body() {
    switch (_phase) {
      case _Phase.loading:
        return const [
          Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),
        ];

      case _Phase.needSignIn:
        return [
          _note(
            _configured
                ? 'Sign in with Google to back up and restore your documents. '
                    'Everything works without an account too — files stay only on this phone.'
                : 'Google sign-in is not set up on this build yet. '
                    'Until Firebase is connected, Docify runs fully on this phone.',
          ),
          if (_configured) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _signIn,
                icon: const Icon(Icons.account_circle_rounded, size: 20),
                label: Text(_busy ? 'Signing in…' : 'Sign in with Google'),
              ),
            ),
          ],
        ];

      case _Phase.needDrive:
        return [
          _note(
            'Allow Docify to save and read files inside its own '
            '"Docify" folder of your Google Drive. No other Drive files '
            'are touched.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _allowDrive,
              icon: const Icon(Icons.folder_shared_rounded, size: 20),
              label: Text(_busy ? 'Opening…' : 'Allow Drive access'),
            ),
          ),
        ];

      case _Phase.ready:
        final plan = _plan!;
        return [
          _stat(
            Icons.upload_rounded,
            '${plan.uploads.length} file${plan.uploads.length == 1 ? '' : 's'} '
            'to back up  ·  ${_mb(plan.uploadBytes)}',
            plan.uploads.isEmpty
                ? 'Nothing new to back up.'
                : 'Newest copies go up; nothing already on Drive is replaced.',
          ),
          const SizedBox(height: 8),
          _stat(
            Icons.download_rounded,
            '${plan.downloads.length} file${plan.downloads.length == 1 ? '' : 's'} '
            'to restore  ·  ${_mb(plan.downloadBytes)}',
            plan.downloads.isEmpty
                ? 'Nothing new to restore.'
                : 'Files only on Drive come down to this phone.',
          ),
          const SizedBox(height: 8),
          _stat(
            Icons.delete_outline_rounded,
            'Nothing on this phone is deleted',
            'Removing a file from Docify never removes your Drive copy.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _close(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _startSync,
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  label: const Text('Sync now'),
                ),
              ),
            ],
          ),
        ];

      case _Phase.running:
        return [
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _total > 0 ? _done / _total : null,
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 12),
          Text(
            _total > 0 ? '$_done of $_total  ·  $_label' : 'Preparing…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep the app open until this finishes.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          ),
        ];

      case _Phase.inSync:
        return [
          _note('Everything is already backed up and up to date.'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _close(),
              child: const Text('Done'),
            ),
          ),
        ];

      case _Phase.done:
        final o = _outcome!;
        final failedNote = o.failed > 0
            ? '\n${o.failed} file(s) failed — try again later.'
            : '';
        return [
          _stat(
            Icons.cloud_done_rounded,
            '${o.uploaded} backed up  ·  ${o.downloaded} restored',
            'Drive and this phone now match. $failedNote'.trim(),
            color:
                o.failed > 0 ? const Color(0xFFEA580C) : AppColors.successChip,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _close(changed: o.downloaded > 0),
              child: const Text('Done'),
            ),
          ),
        ];

      case _Phase.error:
        return [
          _note(_error),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _close(),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _retry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
        ];
    }
  }

  Widget _note(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.bodyText,
        ),
      );

  Widget _stat(IconData icon, String title, String sub, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color ?? AppColors.titleBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _mb(int bytes) {
    final mb = bytes / 1048576;
    if (mb >= 1000) return '${(mb / 1024).toStringAsFixed(1)} GB';
    if (mb >= 10) return '${mb.round()} MB';
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).round()} KB';
  }
}
