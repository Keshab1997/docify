import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_doc.dart';

/// The folders every copy of Docify starts with. Job seekers keep the same
/// few kinds of paper for every application, so these are there from day
/// one and can't be renamed or removed.
enum BuiltInFolder {
  jobForms('Job Forms', 'Application forms, admit cards, fee receipts'),
  certificates('Certificates', 'Marksheets, degree and caste certificates'),
  idProof('ID Proof', 'Aadhaar, PAN, voter ID, passport'),
  photoSign('Photo & Signature', 'Passport photos and signatures'),
  others('Others', 'Anything else');

  const BuiltInFolder(this.label, this.examples);

  final String label;

  /// What belongs here, shown when the user picks a folder.
  final String examples;

  /// The enum name is the folder id: the same id files were filed under
  /// when these were the only folders, so those files stay put.
  DocFolder get folder => DocFolder(id: name, name: label, builtIn: this);
}

/// A folder in My documents: a [BuiltInFolder] or one the user made.
///
/// Folders are labels kept in preferences next to the files, not
/// directories, so the store, renaming and Drive sync all still see one
/// flat list of files.
class DocFolder {
  const DocFolder({required this.id, required this.name, this.builtIn});

  /// Never changes, so a renamed folder keeps its files.
  final String id;
  final String name;

  /// Null for the user's own folders.
  final BuiltInFolder? builtIn;

  bool get isCustom => builtIn == null;

  // Two snapshots of one folder, such as before and after a rename, are
  // the same folder.
  @override
  bool operator ==(Object other) => other is DocFolder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Why [name] can't name a folder, or null if it can. [except] is the id of
/// the folder being renamed, which may keep its own name.
String? folderNameError(
  String name,
  Iterable<DocFolder> folders, {
  String? except,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Enter a folder name';
  if (trimmed.length > DocFolders.maxName) {
    return 'Use ${DocFolders.maxName} characters or fewer';
  }
  final lower = trimmed.toLowerCase();
  for (final folder in folders) {
    if (folder.id != except && folder.name.toLowerCase() == lower) {
      return 'There is already a folder called ${folder.name}';
    }
  }
  return null;
}

/// The folders and which file is in which, read once per screen load.
class DocLibrary {
  const DocLibrary({this.custom = const [], this.filed = const {}});

  /// The user's own folders, A to Z.
  final List<DocFolder> custom;

  /// Folder id by file id, for files that were put in a folder.
  final Map<String, String> filed;

  /// The built-in folders first, in their fixed order, then the user's.
  List<DocFolder> get folders => [
        for (final b in BuiltInFolder.values) b.folder,
        ...custom,
      ];

  DocFolder? byId(String id) {
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  /// The folder [doc] is in. A file never put anywhere, or whose folder is
  /// gone, goes by type: photos to Photo & Signature, since the photo and
  /// signature tools make most of them, and everything else to Others.
  DocFolder folderOf(SavedDoc doc) {
    final id = filed[doc.id];
    final folder = id == null ? null : byId(id);
    if (folder != null) return folder;
    return doc.isImage
        ? BuiltInFolder.photoSign.folder
        : BuiltInFolder.others.folder;
  }
}

/// Reads and writes the [DocLibrary] in preferences.
class DocFolders {
  DocFolders._();

  static const maxName = 40;

  static const _foldersKey = 'doc_folders';

  // Named when the built-in folders were called categories; kept so files
  // filed back then stay where they were put.
  static const _filedKey = 'doc_categories';

  /// Never throws: an unreadable store, or none at all as in widget tests,
  /// just leaves every file in its fallback folder.
  static Future<DocLibrary> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return DocLibrary(
        custom: _readFolders(prefs.getString(_foldersKey)),
        filed: _readFiled(prefs.getString(_filedKey)),
      );
    } catch (_) {
      return const DocLibrary();
    }
  }

  /// Makes a folder of the user's own called [name], already checked with
  /// [folderNameError].
  static Future<DocFolder> create(String name) async {
    final library = await load();
    final folder = DocFolder(
      id: 'f${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
    );
    await _writeFolders([...library.custom, folder]);
    return folder;
  }

  /// Renames the user's folder [id]; its files stay in it.
  static Future<void> rename(String id, String name) async {
    final library = await load();
    await _writeFolders([
      for (final folder in library.custom)
        folder.id == id ? DocFolder(id: id, name: name.trim()) : folder,
    ]);
  }

  /// Removes the user's folder [id]. Files still in it move to Others; when
  /// the user chose to delete them too, the caller has done so already.
  static Future<void> remove(String id) async {
    final library = await load();
    await _writeFolders([
      for (final folder in library.custom) if (folder.id != id) folder,
    ]);
    await _updateFiled((filed) {
      filed.updateAll(
        (_, folder) => folder == id ? BuiltInFolder.others.name : folder,
      );
    });
  }

  /// Puts the documents [ids] in [folder], e.g. everything one upload added.
  static Future<void> file(Iterable<String> ids, DocFolder folder) {
    return _updateFiled((filed) {
      for (final id in ids) {
        filed[id] = folder.id;
      }
    });
  }

  /// Keeps a renamed document in its folder: ids are file names.
  static Future<void> move(String from, String to) {
    return _updateFiled((filed) {
      final folder = filed.remove(from);
      if (folder != null) filed[to] = folder;
    });
  }

  /// Drops a deleted document, so a later file of the same name starts
  /// unfiled instead of inheriting its folder.
  static Future<void> forget(String id) {
    return _updateFiled((filed) => filed.remove(id));
  }

  static List<DocFolder> _readFolders(String? raw) {
    if (raw == null) return [];
    try {
      final seen = <String>{};
      final folders = <DocFolder>[];
      for (final item in jsonDecode(raw) as List<dynamic>) {
        if (item is! Map) continue;
        final id = item['id'];
        final name = item['name'];
        if (id is! String || name is! String || name.trim().isEmpty) continue;
        if (seen.add(id)) folders.add(DocFolder(id: id, name: name));
      }
      return folders
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (_) {
      return [];
    }
  }

  static Map<String, String> _readFiled(String? raw) {
    if (raw == null) return {};
    try {
      return {
        for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeFolders(List<DocFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _foldersKey,
      jsonEncode([
        for (final folder in folders) {'id': folder.id, 'name': folder.name},
      ]),
    );
  }

  static Future<void> _updateFiled(
    void Function(Map<String, String> filed) change,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final filed = _readFiled(prefs.getString(_filedKey));
    change(filed);
    await prefs.setString(_filedKey, jsonEncode(filed));
  }
}
