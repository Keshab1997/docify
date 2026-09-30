import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_doc.dart';

/// The shelves of My documents. Job seekers keep the same few kinds of paper
/// for every application, so each file sits on one of these.
enum DocCategory {
  jobForms('Job Forms', 'Application forms, admit cards, fee receipts'),
  certificates('Certificates', 'Marksheets, degree and caste certificates'),
  idProof('ID Proof', 'Aadhaar, PAN, voter ID, passport'),
  photoSign('Photo & Signature', 'Passport photos and signatures'),
  others('Others', 'Anything else');

  const DocCategory(this.label, this.examples);

  final String label;

  /// What belongs here, shown when the user picks a shelf.
  final String examples;
}

/// Which shelf each file is on, by file id.
///
/// Kept in preferences beside the files rather than in folders or file
/// names, so the store, renaming and Drive sync all stay as they were. The
/// price is that a file restored from Drive comes back unfiled and falls
/// back by type (see [of]) until the user moves it again.
class DocCategories {
  const DocCategories._();

  static const _key = 'doc_categories';

  /// Every filed document. Never throws: an unreadable store, or none at
  /// all as in widget tests, just leaves every file on its fallback shelf.
  static Future<Map<String, DocCategory>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      final names = DocCategory.values.asNameMap();
      final filed = <String, DocCategory>{};
      for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries) {
        final category = names[entry.value];
        if (category != null) filed[entry.key] = category;
      }
      return filed;
    } catch (_) {
      return {};
    }
  }

  /// Puts the documents [ids] on [category], e.g. everything one upload
  /// added.
  static Future<void> file(Iterable<String> ids, DocCategory category) {
    return _update((filed) {
      for (final id in ids) {
        filed[id] = category;
      }
    });
  }

  /// Keeps a renamed document on its shelf: ids are file names.
  static Future<void> move(String from, String to) {
    return _update((filed) {
      final category = filed.remove(from);
      if (category != null) filed[to] = category;
    });
  }

  /// Drops a deleted document, so a later file of the same name starts
  /// unfiled instead of inheriting its shelf.
  static Future<void> forget(String id) {
    return _update((filed) => filed.remove(id));
  }

  /// The shelf [doc] is on: the one it was filed under, otherwise photos
  /// go to Photo & Signature, since the photo and signature tools make most
  /// of them, and everything else to Others.
  static DocCategory of(SavedDoc doc, Map<String, DocCategory> filed) {
    return filed[doc.id] ??
        (doc.isImage ? DocCategory.photoSign : DocCategory.others);
  }

  static Future<void> _update(
    void Function(Map<String, DocCategory> filed) change,
  ) async {
    final filed = await load();
    change(filed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        for (final entry in filed.entries) entry.key: entry.value.name,
      }),
    );
  }
}
