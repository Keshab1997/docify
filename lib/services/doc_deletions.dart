import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _digest(Uint8List bytes) => md5.convert(bytes).toString();

/// Matches Drive's checksum; hashing large imports happens off the UI isolate.
Future<String> documentDigest(Uint8List bytes) => compute(_digest, bytes);

class LocalDeletionSet {
  const LocalDeletionSet({this.digests = const {}, this.names = const {}});

  final Set<String> digests;
  final Set<String> names;

  bool contains(String name, String? digest) {
    if (digest != null && digest.isNotEmpty) return digests.contains(digest);
    return names.contains(name);
  }
}

/// Local-only tombstones. These never delete or modify a user's Drive copy.
/// Content identity survives renames; names are only a fallback for Drive files
/// without a checksum. A deliberate import/restore can clear the suppression.
class DocDeletions {
  DocDeletions._();

  static const _key = 'doc_local_deletions_v1';
  static Future<void> _pending = Future.value();

  static LocalDeletionSet _decode(String? raw) {
    if (raw == null) return const LocalDeletionSet();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return LocalDeletionSet(
        digests: {...(data['digests'] as List<dynamic>? ?? []).whereType<String>()},
        names: {...(data['names'] as List<dynamic>? ?? []).whereType<String>()},
      );
    } catch (_) {
      return const LocalDeletionSet();
    }
  }

  static Future<LocalDeletionSet> load() async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key));
  }

  static Future<void> _change(
    void Function(Set<String> digests, Set<String> names) update,
  ) async {
    final before = _pending;
    final done = Completer<void>();
    _pending = done.future;
    await before;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = _decode(prefs.getString(_key));
      final digests = {...current.digests};
      final names = {...current.names};
      update(digests, names);
      final ok = await prefs.setString(_key, jsonEncode({
        'digests': digests.toList(), 'names': names.toList(),
      }));
      if (!ok) throw StateError('Could not remember this device deletion');
    } finally {
      done.complete();
    }
  }

  static Future<void> record({required String name, required String digest}) {
    return _change((digests, names) {
      digests.add(digest);
      names.add(name);
    });
  }

  static Future<void> allow({required String name, required String digest}) {
    return _change((digests, names) {
      digests.remove(digest);
      names.remove(name);
    });
  }
}
