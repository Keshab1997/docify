import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/doc_meta.dart';

/// Stars, recent-open timestamps, tags, trash and derived file information.
/// Serialized mutations prevent a backup result overwriting a simultaneous edit.
class DocIndex {
  DocIndex._();

  static const _key = 'doc_index_v1';
  static Future<void> _pending = Future.value();

  static Map<String, DocMeta> _decode(String? raw) {
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, DocMeta>{};
      for (final entry in data.entries) {
        try {
          result[entry.key] = DocMeta.fromJson(entry.value as Map<String, dynamic>);
        } catch (_) {
          // One damaged metadata record must not hide the other documents.
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, DocMeta>> load() async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key));
  }

  static Future<void> _change(void Function(Map<String, DocMeta>) update) async {
    final before = _pending;
    final done = Completer<void>();
    _pending = done.future;
    await before;
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = _decode(prefs.getString(_key));
      update(index);
      final ok = await prefs.setString(_key, jsonEncode({
        for (final entry in index.entries) entry.key: entry.value.toJson(),
      }));
      if (!ok) throw StateError('Could not save document metadata');
    } finally {
      done.complete();
    }
  }

  static Future<void> update(String id, DocMeta Function(DocMeta) update) {
    return _change((index) => index[id] = update(index[id] ?? const DocMeta()));
  }

  static Future<void> starred(String id, bool value) =>
      update(id, (meta) => meta.copyWith(starred: value));

  static Future<void> opened(String id) => update(id, (meta) => meta.copyWith(
    openedAt: DateTime.now().millisecondsSinceEpoch,
  ));

  static List<String> normalizeTags(Iterable<String> tags) => {
    for (final tag in tags)
      if (tag.trim().isNotEmpty) tag.trim().toLowerCase().substring(
        0, tag.trim().length.clamp(0, 24).toInt(),
      ),
  }.take(8).toList();

  static Future<void> tags(String id, Iterable<String> values) =>
      update(id, (meta) => meta.copyWith(tags: normalizeTags(values)));

  static Future<void> renamed(String from, String to) {
    if (from == to) return Future.value();
    return _change((index) {
      final metadata = index.remove(from);
      if (metadata != null) index[to] = metadata;
    });
  }

  static Future<void> forget(String id) => _change((index) => index.remove(id));

  static Future<void> recognised(String id, String text, int pages) {
    final trimmed = text.trim();
    return update(id, (meta) => meta.copyWith(
      ocrText: trimmed.substring(0, trimmed.length.clamp(0, 60000).toInt()),
      ocrPages: pages,
    ));
  }
}
