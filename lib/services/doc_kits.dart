import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/application_kit.dart';

/// Kits reference existing local files; attaching never copies or uploads them.
class DocKits {
  DocKits._();
  static const _key = 'doc_application_kits_v1';
  static Future<void> _pending = Future.value();

  static List<ApplicationKit> _decode(String? raw) {
    if (raw == null) return [];
    try {
      final result = <ApplicationKit>[];
      for (final item in jsonDecode(raw) as List<dynamic>) {
        try { result.add(ApplicationKit.fromJson(item as Map<String, dynamic>)); }
        catch (_) { /* Keep other kits if one record is damaged. */ }
      }
      return result;
    } catch (_) { return []; }
  }

  static Future<List<ApplicationKit>> load() async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key));
  }

  static Future<void> _change(void Function(List<ApplicationKit>) update) async {
    final before = _pending;
    final done = Completer<void>();
    _pending = done.future;
    await before;
    try {
      final prefs = await SharedPreferences.getInstance();
      final kits = _decode(prefs.getString(_key));
      update(kits);
      if (!await prefs.setString(_key, jsonEncode(kits.map((kit) => kit.toJson()).toList()))) {
        throw StateError('Could not save application kits');
      }
    } finally { done.complete(); }
  }

  static Future<ApplicationKit> create(String name, {String examId = 'custom', Set<KitSlot>? requiredSlots}) async {
    final kit = ApplicationKit(id: 'kit${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(), examId: examId,
      requiredSlots: requiredSlots ?? const {KitSlot.photo, KitSlot.signature, KitSlot.idProof, KitSlot.certificate});
    await save(kit);
    return kit;
  }

  static Future<void> save(ApplicationKit kit) => _change((kits) {
    if (kit.name.trim().isEmpty || kit.name.length > 60) { throw ArgumentError('Use a kit name of 1–60 characters'); }
    if (kits.any((old) => old.id != kit.id && old.name.toLowerCase() == kit.name.toLowerCase())) {
      throw StateError('A kit with this name already exists');
    }
    final index = kits.indexWhere((old) => old.id == kit.id);
    if (index < 0) { kits.add(kit); } else { kits[index] = kit; }
  });

  static Future<void> attach(String kitId, KitSlot slot, String? docId) => _change((kits) {
    final index = kits.indexWhere((kit) => kit.id == kitId);
    if (index < 0) throw StateError('Kit no longer exists');
    final files = {...kits[index].files};
    if (docId == null) { files.remove(slot); } else { files[slot] = docId; }
    kits[index] = kits[index].copyWith(files: files);
  });

  static Future<void> renamed(String from, String to) => _change((kits) {
    for (var i = 0; i < kits.length; i++) {
      kits[i] = kits[i].copyWith(files: {
        for (final entry in kits[i].files.entries) entry.key: entry.value == from ? to : entry.value,
      });
    }
  });

  static Future<void> remove(String id) => _change((kits) => kits.removeWhere((kit) => kit.id == id));
}
